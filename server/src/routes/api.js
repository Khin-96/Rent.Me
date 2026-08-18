const express = require('express');
const router = express.Router();

// Middlewares
const { authenticate, requireRole } = require('../middleware/auth');
const validate = require('../middleware/validate');

// Schemas
const {
  registerSchema,
  loginSchema,
  createPropertySchema,
  updatePropertySchema,
  createInquirySchema,
  createMessageSchema,
  createReportSchema,
  updateReportStatusSchema,
} = require('../lib/schemas');

// Controllers
const auth = require('../controllers/auth');
const properties = require('../controllers/properties');
const images = require('../controllers/images');
const videos = require('../controllers/videos');
const favorites = require('../controllers/favorites');
const inquiries = require('../controllers/inquiries');
const admin = require('../controllers/admin');
const traffic = require('../controllers/traffic');

// --- Auth Routes ---
router.post('/auth/register', validate(registerSchema), auth.register);
router.post('/auth/login', validate(loginSchema), auth.login);
router.get('/auth/me', authenticate, auth.getMe);

// --- Property Routes ---
router.get('/properties', properties.getProperties);
router.get('/properties/:id', properties.getPropertyById);
router.post('/properties', authenticate, requireRole(['LANDLORD', 'ADMIN']), validate(createPropertySchema), properties.createProperty);
router.put('/properties/:id', authenticate, requireRole(['LANDLORD', 'ADMIN']), validate(updatePropertySchema), properties.updateProperty);
router.delete('/properties/:id', authenticate, requireRole(['LANDLORD', 'ADMIN']), properties.deleteProperty);
router.patch('/properties/:id/status', authenticate, requireRole(['LANDLORD', 'ADMIN']), properties.updatePropertyStatus);

// --- Image Routes ---
router.post('/images/upload', authenticate, requireRole(['LANDLORD', 'ADMIN']), images.uploadParser, images.uploadImage);
router.delete('/images/:publicId', authenticate, requireRole(['LANDLORD', 'ADMIN']), images.deleteImage);

// --- Video Routes ---
router.post('/videos/upload', authenticate, requireRole(['LANDLORD', 'ADMIN']), videos.uploadParser, videos.uploadVideo);
router.delete('/videos/:publicId', authenticate, requireRole(['LANDLORD', 'ADMIN']), videos.deleteVideo);

router.get('/traffic', traffic.getTraffic);

// --- Favorites Routes ---
router.get('/favorites', authenticate, requireRole(['TENANT']), favorites.getFavorites);
router.post('/favorites/:propertyId', authenticate, requireRole(['TENANT']), favorites.addFavorite);
router.delete('/favorites/:propertyId', authenticate, requireRole(['TENANT']), favorites.deleteFavorite);

// --- Inquiry / Chat Routes ---
router.get('/inquiries', authenticate, inquiries.getInquiries);
router.get('/inquiries/:id/messages', authenticate, inquiries.getInquiryMessages);
router.post('/inquiries', authenticate, requireRole(['TENANT']), validate(createInquirySchema), inquiries.createInquiry);
router.post('/inquiries/:id/messages', authenticate, validate(createMessageSchema), inquiries.sendMessage);

// --- Report Routes ---
router.post('/reports', authenticate, validate(createReportSchema), admin.createReport);

// --- Admin Moderate Routes ---
router.get('/admin/users', authenticate, requireRole(['ADMIN']), admin.getUsers);
router.patch('/admin/users/:id/suspend', authenticate, requireRole(['ADMIN']), admin.suspendUser);
router.get('/admin/reports', authenticate, requireRole(['ADMIN']), admin.getReports);
router.patch('/admin/reports/:id', authenticate, requireRole(['ADMIN']), validate(updateReportStatusSchema), admin.updateReportStatus);

module.exports = router;
