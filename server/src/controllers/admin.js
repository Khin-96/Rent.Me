const prisma = require('../lib/db');

// Report Listing (Available to authenticated tenants and landlords)
const createReport = async (req, res, next) => {
  try {
    const reporterId = req.user.id;
    const { propertyId, reason, description } = req.body;

    const property = await prisma.property.findUnique({ where: { id: propertyId } });
    if (!property) {
      return res.status(404).json({ error: 'Property listing not found' });
    }

    const report = await prisma.report.create({
      data: {
        reporterId,
        propertyId,
        reason,
        description,
      },
    });

    res.status(201).json(report);
  } catch (error) {
    next(error);
  }
};

// Admin Moderation: Retrieve all users
const getUsers = async (req, res, next) => {
  try {
    const users = await prisma.user.findMany({
      select: {
        id: true,
        email: true,
        role: true,
        name: true,
        phone: true,
        avatarUrl: true,
        isVerified: true,
        verificationBadge: true,
        isSuspended: true,
        createdAt: true,
      },
      orderBy: { createdAt: 'desc' },
    });

    res.status(200).json(users);
  } catch (error) {
    next(error);
  }
};

// Admin Moderation: Toggle user suspension
const suspendUser = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { suspend } = req.body; // boolean

    if (typeof suspend !== 'boolean') {
      return res.status(400).json({ error: 'Missing suspend state boolean' });
    }

    if (id === req.user.id) {
      return res.status(400).json({ error: 'You cannot suspend your own admin account' });
    }

    const user = await prisma.user.findUnique({ where: { id } });
    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    const updatedUser = await prisma.user.update({
      where: { id },
      data: { isSuspended: suspend },
      select: {
        id: true,
        email: true,
        name: true,
        role: true,
        isSuspended: true,
      },
    });

    res.status(200).json(updatedUser);
  } catch (error) {
    next(error);
  }
};

// Admin Moderation: Retrieve listing reports
const getReports = async (req, res, next) => {
  try {
    const reports = await prisma.report.findMany({
      include: {
        reporter: {
          select: { id: true, name: true, email: true },
        },
        property: {
          include: {
            images: { take: 1 },
          },
        },
      },
      orderBy: { createdAt: 'desc' },
    });

    res.status(200).json(reports);
  } catch (error) {
    next(error);
  }
};

// Admin Moderation: Update report state
const updateReportStatus = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { status } = req.body;

    const report = await prisma.report.findUnique({ where: { id } });
    if (!report) {
      return res.status(404).json({ error: 'Report not found' });
    }

    const updatedReport = await prisma.report.update({
      where: { id },
      data: {
        status,
        reviewedAt: new Date(),
      },
    });

    res.status(200).json(updatedReport);
  } catch (error) {
    next(error);
  }
};

module.exports = {
  createReport,
  getUsers,
  suspendUser,
  getReports,
  updateReportStatus,
};
