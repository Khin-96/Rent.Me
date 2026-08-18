const prisma = require('../lib/db');

const getInquiries = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const role = req.user.role;

    let inquiries;

    if (role === 'TENANT') {
      inquiries = await prisma.inquiry.findMany({
        where: { tenantId: userId },
        include: {
          property: {
            select: { id: true, name: true, rentAmount: true },
          },
          landlord: {
            select: { id: true, name: true, email: true, phone: true, avatarUrl: true },
          },
          messages: {
            orderBy: { createdAt: 'desc' },
            take: 1,
          },
        },
        orderBy: { updatedAt: 'desc' },
      });
    } else if (role === 'LANDLORD') {
      inquiries = await prisma.inquiry.findMany({
        where: { landlordId: userId },
        include: {
          property: {
            select: { id: true, name: true, rentAmount: true },
          },
          tenant: {
            select: { id: true, name: true, email: true, phone: true, avatarUrl: true },
          },
          messages: {
            orderBy: { createdAt: 'desc' },
            take: 1,
          },
        },
        orderBy: { updatedAt: 'desc' },
      });
    } else if (role === 'ADMIN') {
      inquiries = await prisma.inquiry.findMany({
        include: {
          property: true,
          tenant: true,
          landlord: true,
          messages: {
            orderBy: { createdAt: 'desc' },
            take: 1,
          },
        },
        orderBy: { updatedAt: 'desc' },
      });
    }

    res.status(200).json(inquiries);
  } catch (error) {
    next(error);
  }
};

const getInquiryMessages = async (req, res, next) => {
  try {
    const { id } = req.params;
    const userId = req.user.id;
    const role = req.user.role;

    const inquiry = await prisma.inquiry.findUnique({
      where: { id },
      include: {
        property: true,
        tenant: true,
        landlord: true,
      },
    });

    if (!inquiry) {
      return res.status(404).json({ error: 'Inquiry thread not found' });
    }

    // Verify access
    if (inquiry.tenantId !== userId && inquiry.landlordId !== userId && role !== 'ADMIN') {
      return res.status(403).json({ error: 'You do not have access to this conversation' });
    }

    // Mark as read
    if (inquiry.tenantId === userId) {
      await prisma.inquiry.update({
        where: { id },
        data: { isReadByTenant: true },
      });
    } else if (inquiry.landlordId === userId) {
      await prisma.inquiry.update({
        where: { id },
        data: { isReadByLandlord: true },
      });
    }

    const messages = await prisma.message.findMany({
      where: { inquiryId: id },
      orderBy: { createdAt: 'asc' },
      include: {
        sender: {
          select: { id: true, name: true, role: true, avatarUrl: true },
        },
      },
    });

    res.status(200).json({ inquiry, messages });
  } catch (error) {
    next(error);
  }
};

const createInquiry = async (req, res, next) => {
  try {
    const tenantId = req.user.id;
    const { propertyId, subject, message } = req.body;

    // Verify property exists
    const property = await prisma.property.findUnique({ where: { id: propertyId } });
    if (!property) {
      return res.status(404).json({ error: 'Property not found' });
    }

    // Verify tenant isn't landording their own property
    if (property.landlordId === tenantId) {
      return res.status(400).json({ error: 'You cannot send an inquiry on your own property' });
    }

    // Create inquiry and first message in a transaction
    const result = await prisma.$transaction(async (tx) => {
      const inquiry = await tx.inquiry.create({
        data: {
          tenantId,
          landlordId: property.landlordId,
          propertyId,
          subject,
          isReadByLandlord: false,
          isReadByTenant: true,
        },
      });

      const firstMsg = await tx.message.create({
        data: {
          inquiryId: inquiry.id,
          senderId: tenantId,
          body: message,
        },
      });

      return { inquiry, firstMsg };
    });

    res.status(201).json(result);
  } catch (error) {
    next(error);
  }
};

const sendMessage = async (req, res, next) => {
  try {
    const { id } = req.params; // inquiryId
    const senderId = req.user.id;
    const { body } = req.body;

    const inquiry = await prisma.inquiry.findUnique({ where: { id } });
    if (!inquiry) {
      return res.status(404).json({ error: 'Inquiry thread not found' });
    }

    // Verify access
    if (inquiry.tenantId !== senderId && inquiry.landlordId !== senderId && req.user.role !== 'ADMIN') {
      return res.status(403).json({ error: 'You do not have access to this conversation' });
    }

    // Create message and update inquiry read statuses
    const isTenantSender = inquiry.tenantId === senderId;

    const result = await prisma.$transaction(async (tx) => {
      const message = await tx.message.create({
        data: {
          inquiryId: id,
          senderId,
          body,
        },
        include: {
          sender: {
            select: { id: true, name: true, role: true, avatarUrl: true },
          },
        },
      });

      await tx.inquiry.update({
        where: { id },
        data: {
          isReadByLandlord: isTenantSender ? false : true,
          isReadByTenant: isTenantSender ? true : false,
          updatedAt: new Date(), // touch updated at to sort threads
        },
      });

      return message;
    });

    res.status(201).json(result);
  } catch (error) {
    next(error);
  }
};

module.exports = {
  getInquiries,
  getInquiryMessages,
  createInquiry,
  sendMessage,
};
