const prisma = require('../lib/db');

// Helper to format property output: converts comma-separated amenities back to an array
const formatProperty = (p) => {
  if (!p) return null;
  return {
    ...p,
    amenities: p.amenities ? p.amenities.split(',') : [],
  };
};

const getProperties = async (req, res, next) => {
  try {
    const {
      type,
      minRent,
      maxRent,
      status,
      landlordId,
      minLat,
      maxLat,
      minLng,
      maxLng,
      amenities,
      q,
    } = req.query;

    const where = {};

    if (landlordId) {
      where.landlordId = landlordId;
    }

    if (status) {
      where.status = status;
    } else if (!landlordId) {
      where.status = 'AVAILABLE';
    }

    if (type) {
      where.type = type;
    }

    if (minRent || maxRent) {
      where.rentAmount = {};
      if (minRent) where.rentAmount.gte = parseInt(minRent);
      if (maxRent) where.rentAmount.lte = parseInt(maxRent);
    }

    if (minLat && maxLat && minLng && maxLng) {
      where.latitude = {
        gte: parseFloat(minLat),
        lte: parseFloat(maxLat),
      };
      where.longitude = {
        gte: parseFloat(minLng),
        lte: parseFloat(maxLng),
      };
    }

    if (q) {
      where.OR = [
        { name: { contains: q } }, // SQLite doesn't natively support mode: 'insensitive' via contains easily in prisma without setup, but contains is good enough for dev
        { address: { contains: q } },
        { neighbourhood: { contains: q } },
        { city: { contains: q } },
      ];
    }

    let properties = await prisma.property.findMany({
      where,
      include: {
        images: {
          orderBy: { order: 'asc' },
        },
        videos: true,
        landlord: {
          select: {
            id: true,
            name: true,
            email: true,
            phone: true,
            avatarUrl: true,
            verificationBadge: true,
          },
        },
      },
      orderBy: { createdAt: 'desc' },
    });

    // Handle amenities filtering in memory for SQLite
    if (amenities) {
      const amenityArray = (Array.isArray(amenities) ? amenities : [amenities])
        .flatMap((value) => String(value).split(','))
        .map((value) => value.trim())
        .filter(Boolean);
      if (amenityArray.length > 0) {
        properties = properties.filter((p) => {
          const pAmenities = p.amenities ? p.amenities.split(',') : [];
          return amenityArray.every((a) => pAmenities.includes(a));
        });
      }
    }

    res.status(200).json(properties.map(formatProperty));
  } catch (error) {
    next(error);
  }
};

const getPropertyById = async (req, res, next) => {
  try {
    const { id } = req.params;

    const property = await prisma.property.findUnique({
      where: { id },
      include: {
        images: {
          orderBy: { order: 'asc' },
        },
        videos: true,
        units: true,
        landlord: {
          select: {
            id: true,
            name: true,
            email: true,
            phone: true,
            avatarUrl: true,
            verificationBadge: true,
          },
        },
      },
    });

    if (!property) {
      return res.status(404).json({ error: 'Property not found' });
    }

    res.status(200).json(formatProperty(property));
  } catch (error) {
    next(error);
  }
};

const createProperty = async (req, res, next) => {
  try {
    const {
      name,
      description,
      type,
      latitude,
      longitude,
      address,
      neighbourhood,
      city,
      rentAmount,
      depositAmount,
      bedrooms,
      bathrooms,
      size,
      amenities,
      images,
      videos,
    } = req.body;

    const amenitiesString = amenities && Array.isArray(amenities) ? amenities.join(',') : '';

    const property = await prisma.property.create({
      data: {
        landlordId: req.user.id,
        name,
        description,
        type,
        latitude,
        longitude,
        address,
        neighbourhood,
        city: city || 'Nairobi',
        rentAmount,
        depositAmount,
        bedrooms,
        bathrooms,
        size,
        amenities: amenitiesString,
        images: {
          create: (images || []).map((img, idx) => ({
            cloudinaryPublicId: img.cloudinaryPublicId,
            cloudinaryUrl: img.cloudinaryUrl,
            thumbnailUrl: img.thumbnailUrl || img.cloudinaryUrl,
            isCover: img.isCover || idx === 0,
            order: img.order || idx,
          })),
        },
        videos: {
          create: (videos || []).map((vid) => ({
            cloudinaryPublicId: vid.cloudinaryPublicId,
            cloudinaryUrl: vid.cloudinaryUrl,
            thumbnailUrl: vid.thumbnailUrl || vid.cloudinaryUrl,
          })),
        },
      },
      include: {
        images: true,
        videos: true,
      },
    });

    res.status(201).json(formatProperty(property));
  } catch (error) {
    next(error);
  }
};

const updateProperty = async (req, res, next) => {
  try {
    const { id } = req.params;
    const updateData = { ...req.body };

    const property = await prisma.property.findUnique({ where: { id } });
    if (!property) {
      return res.status(404).json({ error: 'Property not found' });
    }

    if (property.landlordId !== req.user.id && req.user.role !== 'ADMIN') {
      return res.status(403).json({ error: 'You are not authorized to update this property' });
    }

    if (updateData.amenities && Array.isArray(updateData.amenities)) {
      updateData.amenities = updateData.amenities.join(',');
    }

    // Handle videos/images if passed as direct relation inputs
    let videosCreate;
    if (updateData.videos) {
      videosCreate = updateData.videos;
      delete updateData.videos;
    }
    let imagesCreate;
    if (Array.isArray(updateData.images)) {
      imagesCreate = updateData.images;
      delete updateData.images;
    }

    const updatedProperty = await prisma.property.update({
      where: { id },
      data: {
        ...updateData,
        ...(imagesCreate && {
          images: {
            deleteMany: {},
            create: imagesCreate.map((img, idx) => ({
              cloudinaryPublicId: img.cloudinaryPublicId,
              cloudinaryUrl: img.cloudinaryUrl,
              thumbnailUrl: img.thumbnailUrl || img.cloudinaryUrl,
              isCover: img.isCover || idx === 0,
              order: img.order || idx,
            })),
          },
        }),
        ...(videosCreate && {
          videos: {
            deleteMany: {},
            create: videosCreate.map((vid) => ({
              cloudinaryPublicId: vid.cloudinaryPublicId,
              cloudinaryUrl: vid.cloudinaryUrl,
              thumbnailUrl: vid.thumbnailUrl || vid.cloudinaryUrl,
            })),
          },
        }),
      },
      include: {
        images: true,
        videos: true,
      },
    });

    res.status(200).json(formatProperty(updatedProperty));
  } catch (error) {
    next(error);
  }
};

const deleteProperty = async (req, res, next) => {
  try {
    const { id } = req.params;

    const property = await prisma.property.findUnique({ where: { id } });
    if (!property) {
      return res.status(404).json({ error: 'Property not found' });
    }

    if (property.landlordId !== req.user.id && req.user.role !== 'ADMIN') {
      return res.status(403).json({ error: 'You are not authorized to delete this property' });
    }

    await prisma.property.delete({ where: { id } });

    res.status(200).json({ message: 'Property deleted successfully' });
  } catch (error) {
    next(error);
  }
};

const updatePropertyStatus = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { status } = req.body;

    if (!['AVAILABLE', 'OCCUPIED', 'PAUSED'].includes(status)) {
      return res.status(400).json({ error: 'Invalid status value' });
    }

    const property = await prisma.property.findUnique({ where: { id } });
    if (!property) {
      return res.status(404).json({ error: 'Property not found' });
    }

    if (property.landlordId !== req.user.id && req.user.role !== 'ADMIN') {
      return res.status(403).json({ error: 'You are not authorized to edit this property status' });
    }

    const updated = await prisma.property.update({
      where: { id },
      data: { status },
    });

    res.status(200).json(formatProperty(updated));
  } catch (error) {
    next(error);
  }
};

module.exports = {
  getProperties,
  getPropertyById,
  createProperty,
  updateProperty,
  deleteProperty,
  updatePropertyStatus,
};
