const { z } = require('zod');

const RoleEnum = z.enum(['TENANT', 'LANDLORD', 'ADMIN']);
const PropertyTypeEnum = z.enum([
  'BEDSITTER', 'STUDIO', 'ONE_BED', 'TWO_BED', 'THREE_BED_PLUS',
  'APARTMENT', 'HOUSE', 'VILLA', 'COMMERCIAL',
]);
const PropertyStatusEnum = z.enum(['AVAILABLE', 'OCCUPIED', 'PAUSED']);
const AmenityEnum = z.enum([
  'WATER', 'PARKING', 'SECURITY', 'WIFI', 'ELECTRICITY', 'BALCONY', 'LAUNDRY', 'GYM', 'SWIMMING_POOL',
  'FURNISHED', 'GENERATOR', 'CCTV',
]);
const ReportReasonEnum = z.enum([
  'PROPERTY_DOES_NOT_EXIST', 'WRONG_LOCATION', 'WRONG_PRICE', 'FRAUD_SUSPICIOUS', 'ALREADY_OCCUPIED', 'MISLEADING_INFORMATION', 'OTHER'
]);
const ReportStatusEnum = z.enum(['PENDING', 'REVIEWED', 'RESOLVED', 'DISMISSED']);
const InquiryStatusEnum = z.enum(['OPEN', 'RESPONDED', 'CLOSED']);

// Auth Schemas
const registerSchema = z.object({
  body: z.object({
    email: z.string().email('Invalid email address'),
    password: z.string().min(6, 'Password must be at least 6 characters long'),
    role: RoleEnum.default('TENANT'),
    name: z.string().min(2, 'Name must be at least 2 characters'),
    phone: z.string().optional().nullable(),
  }),
});

const loginSchema = z.object({
  body: z.object({
    email: z.string().email('Invalid email address'),
    password: z.string().min(1, 'Password is required'),
  }),
});

// Property Schemas
const createPropertySchema = z.object({
  body: z.object({
    name: z.string().min(3, 'Property name is required'),
    description: z.string().optional(),
    type: PropertyTypeEnum,
    latitude: z.number({ required_error: 'Latitude is required' }),
    longitude: z.number({ required_error: 'Longitude is required' }),
    address: z.string().min(3, 'Address is required'),
    neighbourhood: z.string().optional(),
    city: z.string().default('Nairobi'),
    rentAmount: z.number().int().positive('Rent must be a positive integer'),
    depositAmount: z.number().int().positive().optional(),
    bedrooms: z.number().int().nonnegative().optional(),
    bathrooms: z.number().int().nonnegative().optional(),
    size: z.number().positive().optional(),
    amenities: z.array(AmenityEnum).default([]),
    images: z.array(z.object({
      cloudinaryPublicId: z.string(),
      cloudinaryUrl: z.string(),
      thumbnailUrl: z.string().optional(),
      isCover: z.boolean().default(false),
      order: z.number().default(0),
    })).optional(),
    videos: z.array(z.object({
      cloudinaryPublicId: z.string(),
      cloudinaryUrl: z.string(),
      thumbnailUrl: z.string().optional(),
    })).optional(),
  }),
});

const updatePropertySchema = z.object({
  body: z.object({
    name: z.string().min(3).optional(),
    description: z.string().optional(),
    type: PropertyTypeEnum.optional(),
    latitude: z.number().optional(),
    longitude: z.number().optional(),
    address: z.string().min(3).optional(),
    neighbourhood: z.string().optional(),
    city: z.string().optional(),
    rentAmount: z.number().int().positive().optional(),
    depositAmount: z.number().int().positive().optional(),
    bedrooms: z.number().int().nonnegative().optional(),
    bathrooms: z.number().int().nonnegative().optional(),
    size: z.number().positive().optional(),
    status: PropertyStatusEnum.optional(),
    amenities: z.array(AmenityEnum).optional(),
    images: z.array(z.object({
      cloudinaryPublicId: z.string(),
      cloudinaryUrl: z.string(),
      thumbnailUrl: z.string().optional(),
      isCover: z.boolean().default(false),
      order: z.number().default(0),
    })).optional(),
    videos: z.array(z.object({
      cloudinaryPublicId: z.string(),
      cloudinaryUrl: z.string(),
      thumbnailUrl: z.string().optional(),
    })).optional(),
  }),
});

// Inquiry / Message Schemas
const createInquirySchema = z.object({
  body: z.object({
    propertyId: z.string().min(1, 'Property ID is required'),
    subject: z.string().min(3, 'Subject must be at least 3 characters'),
    message: z.string().min(1, 'Initial message is required'),
  }),
});

const createMessageSchema = z.object({
  body: z.object({
    body: z.string().min(1, 'Message body cannot be empty'),
  }),
});

// Report Schemas
const createReportSchema = z.object({
  body: z.object({
    propertyId: z.string().min(1, 'Property ID is required'),
    reason: ReportReasonEnum,
    description: z.string().optional(),
  }),
});

const updateReportStatusSchema = z.object({
  body: z.object({
    status: ReportStatusEnum,
  }),
});

module.exports = {
  registerSchema,
  loginSchema,
  createPropertySchema,
  updatePropertySchema,
  createInquirySchema,
  createMessageSchema,
  createReportSchema,
  updateReportStatusSchema,
};
