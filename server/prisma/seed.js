const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcryptjs');

const prisma = new PrismaClient();

async function main() {
  console.log('Clearing database...');
  await prisma.favorite.deleteMany({});
  await prisma.message.deleteMany({});
  await prisma.inquiry.deleteMany({});
  await prisma.report.deleteMany({});
  await prisma.propertyImage.deleteMany({});
  await prisma.propertyUnit.deleteMany({});
  await prisma.property.deleteMany({});
  await prisma.user.deleteMany({});

  console.log('Seeding users...');
  const passwordHash = await bcrypt.hash('password', 10);

  const tenant = await prisma.user.create({
    data: {
      email: 'tenant@example.com',
      passwordHash,
      role: 'TENANT',
      name: 'John Tenant',
      phone: '+254712345678',
      isVerified: true,
    },
  });

  const landlord = await prisma.user.create({
    data: {
      email: 'landlord@example.com',
      passwordHash,
      role: 'LANDLORD',
      name: 'James Landlord',
      phone: '+254722222222',
      isVerified: true,
      verificationBadge: true,
    },
  });

  const admin = await prisma.user.create({
    data: {
      email: 'admin@example.com',
      passwordHash,
      role: 'ADMIN',
      name: 'Alice Admin',
      phone: '+254733333333',
      isVerified: true,
    },
  });

  console.log('Seeding properties...');

  // 1. Roysambu 1 Bed
  const prop1 = await prisma.property.create({
    data: {
      landlordId: landlord.id,
      name: 'Modern 1 Bedroom Apartment',
      description: 'Stunning modern 1 bedroom apartment with 24/7 security, high-speed Wi-Fi, constant water supply, and spacious parking. Near Mall and Bypass.',
      type: 'ONE_BED',
      latitude: -1.2185,
      longitude: 36.8885,
      address: 'TRM Drive, Roysambu',
      neighbourhood: 'Roysambu',
      city: 'Nairobi',
      rentAmount: 12000,
      depositAmount: 12000,
      status: 'AVAILABLE',
      isVerified: true,
      amenities: 'WATER,SECURITY,WIFI,PARKING,BALCONY',
    },
  });

  await prisma.propertyImage.create({
    data: {
      propertyId: prop1.id,
      cloudinaryPublicId: 'seed_prop1',
      cloudinaryUrl: 'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?auto=format&fit=crop&w=800&q=80',
      isCover: true,
    },
  });

  // 2. Kasarani Bedsitter
  const prop2 = await prisma.property.create({
    data: {
      landlordId: landlord.id,
      name: 'Cozy Bedsitter Kasarani',
      description: 'Convenient and affordable bedsitter located near Kasarani stage. Constant water supply and tiled floors. Very close to Thika Road.',
      type: 'BEDSITTER',
      latitude: -1.2220,
      longitude: 36.9010,
      address: 'Kasarani Mwiki Road',
      neighbourhood: 'Kasarani',
      city: 'Nairobi',
      rentAmount: 7500,
      depositAmount: 7500,
      status: 'AVAILABLE',
      isVerified: false,
      amenities: 'WATER,ELECTRICITY',
    },
  });

  await prisma.propertyImage.create({
    data: {
      propertyId: prop2.id,
      cloudinaryPublicId: 'seed_prop2',
      cloudinaryUrl: 'https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?auto=format&fit=crop&w=800&q=80',
      isCover: true,
    },
  });

  // 3. Roysambu Studio
  const prop3 = await prisma.property.create({
    data: {
      landlordId: landlord.id,
      name: 'Sleek Studio Roysambu Bypass',
      description: 'High-end studio apartment with rooftop access, reliable Wi-Fi connection, card access control security, and hot shower.',
      type: 'STUDIO',
      latitude: -1.2150,
      longitude: 36.8840,
      address: 'Lumiere Court, Roysambu',
      neighbourhood: 'Roysambu',
      city: 'Nairobi',
      rentAmount: 10000,
      depositAmount: 10000,
      status: 'AVAILABLE',
      isVerified: true,
      amenities: 'WATER,SECURITY,WIFI,ELECTRICITY',
    },
  });

  await prisma.propertyImage.create({
    data: {
      propertyId: prop3.id,
      cloudinaryPublicId: 'seed_prop3',
      cloudinaryUrl: 'https://images.unsplash.com/photo-1536376072261-38c75010e6c9?auto=format&fit=crop&w=800&q=80',
      isCover: true,
    },
  });

  // 4. Westlands Executive 2 Bed
  const prop4 = await prisma.property.create({
    data: {
      landlordId: landlord.id,
      name: 'Westlands Premium 2 Bedroom',
      description: 'Luxurious executive 2 bedroom apartment in the heart of Westlands. Features backup generator, high-speed lift, gym, swimming pool, and premium finishes.',
      type: 'TWO_BED',
      latitude: -1.2635,
      longitude: 36.8025,
      address: 'Raphta Road, Westlands',
      neighbourhood: 'Westlands',
      city: 'Nairobi',
      rentAmount: 45000,
      depositAmount: 45000,
      status: 'AVAILABLE',
      isVerified: true,
      amenities: 'WATER,SECURITY,WIFI,PARKING,BALCONY,GYM,SWIMMING_POOL,ELECTRICITY',
    },
  });

  await prisma.propertyImage.create({
    data: {
      propertyId: prop4.id,
      cloudinaryPublicId: 'seed_prop4',
      cloudinaryUrl: 'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?auto=format&fit=crop&w=800&q=80',
      isCover: true,
    },
  });

  // 5. Kilimani Studio
  const prop5 = await prisma.property.create({
    data: {
      landlordId: landlord.id,
      name: 'Studio Apartment in Kilimani',
      description: 'Elegant studio apartment in Kilimani. Fully tiled, constant borehole water, rooftop laundry hanging area, and high speed elevator.',
      type: 'STUDIO',
      latitude: -1.2990,
      longitude: 36.7905,
      address: 'Chania Avenue, Kilimani',
      neighbourhood: 'Kilimani',
      city: 'Nairobi',
      rentAmount: 22000,
      depositAmount: 22000,
      status: 'AVAILABLE',
      isVerified: true,
      amenities: 'WATER,SECURITY,WIFI,BALCONY,LAUNDRY',
    },
  });

  await prisma.propertyImage.create({
    data: {
      propertyId: prop5.id,
      cloudinaryPublicId: 'seed_prop5',
      cloudinaryUrl: 'https://images.unsplash.com/photo-1484154218962-a197022b5858?auto=format&fit=crop&w=800&q=80',
      isCover: true,
    },
  });

  console.log('Database seeded successfully!');
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
