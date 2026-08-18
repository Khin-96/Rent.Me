const prisma = require('../lib/db');

// Helper to format property output: converts comma-separated amenities back to an array
const formatProperty = (p) => {
  if (!p) return null;
  return {
    ...p,
    amenities: p.amenities ? p.amenities.split(',') : [],
  };
};

const getFavorites = async (req, res, next) => {
  try {
    const tenantId = req.user.id;

    const favorites = await prisma.favorite.findMany({
      where: { tenantId },
      include: {
        property: {
          include: {
            images: {
              orderBy: { order: 'asc' },
            },
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
        },
      },
      orderBy: { createdAt: 'desc' },
    });

    // Map to return formatted property objects
    const properties = favorites.map((fav) => formatProperty(fav.property));

    res.status(200).json(properties);
  } catch (error) {
    next(error);
  }
};

const addFavorite = async (req, res, next) => {
  try {
    const tenantId = req.user.id;
    const { propertyId } = req.params;

    const property = await prisma.property.findUnique({ where: { id: propertyId } });
    if (!property) {
      return res.status(404).json({ error: 'Property not found' });
    }

    // Check if already favorited
    const existing = await prisma.favorite.findUnique({
      where: {
        tenantId_propertyId: {
          tenantId,
          propertyId,
        },
      },
    });

    if (existing) {
      return res.status(400).json({ error: 'Property already favorited' });
    }

    const favorite = await prisma.favorite.create({
      data: {
        tenantId,
        propertyId,
      },
    });

    res.status(201).json(favorite);
  } catch (error) {
    next(error);
  }
};

const deleteFavorite = async (req, res, next) => {
  try {
    const tenantId = req.user.id;
    const { propertyId } = req.params;

    await prisma.favorite.delete({
      where: {
        tenantId_propertyId: {
          tenantId,
          propertyId,
        },
      },
    });

    res.status(200).json({ message: 'Property removed from favorites' });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  getFavorites,
  addFavorite,
  deleteFavorite,
};
