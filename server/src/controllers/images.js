const multer = require('multer');
const { cloudinary, isCloudinaryConfigured } = require('../lib/cloudinary_config');

// Multer memory storage configuration
const storage = multer.memoryStorage();
const upload = multer({
  storage,
  limits: { fileSize: 5 * 1024 * 1024 }, // 5MB limit
  fileFilter: (req, file, cb) => {
    if (file.mimetype.startsWith('image/')) {
      cb(null, true);
    } else {
      cb(new Error('Only image files are allowed'), false);
    }
  },
});

// Unsplash mock images for realistic looking fallbacks
const mockPropertyImages = [
  'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?auto=format&fit=crop&w=800&q=80',
  'https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?auto=format&fit=crop&w=800&q=80',
  'https://images.unsplash.com/photo-1536376072261-38c75010e6c9?auto=format&fit=crop&w=800&q=80',
  'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?auto=format&fit=crop&w=800&q=80',
  'https://images.unsplash.com/photo-1484154218962-a197022b5858?auto=format&fit=crop&w=800&q=80',
  'https://images.unsplash.com/photo-1505691938895-1758d7feb511?auto=format&fit=crop&w=800&q=80',
  'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?auto=format&fit=crop&w=800&q=80',
];

const uploadImage = async (req, res, next) => {
  try {
    if (!req.file) {
      return res.status(400).json({ error: 'No image file uploaded' });
    }

    if (!isCloudinaryConfigured) {
      // Return a beautiful mock image from Unsplash
      const randomIndex = Math.floor(Math.random() * mockPropertyImages.length);
      const url = mockPropertyImages[randomIndex];
      const publicId = `mock_pub_${Date.now()}_${Math.floor(Math.random() * 1000)}`;
      
      // Simulate delay
      await new Promise((resolve) => setTimeout(resolve, 800));

      return res.status(200).json({
        cloudinaryPublicId: publicId,
        cloudinaryUrl: url,
        thumbnailUrl: url,
      });
    }

    // Upload to Cloudinary
    const fileBase64 = `data:${req.file.mimetype};base64,${req.file.buffer.toString('base64')}`;
    const result = await cloudinary.uploader.upload(fileBase64, {
      folder: 'habitathub_listings',
      transformation: [{ width: 1200, height: 800, crop: 'limit' }],
    });

    const thumbnailUrl = cloudinary.url(result.public_id, {
      width: 400,
      height: 300,
      crop: 'fill',
    });

    res.status(200).json({
      cloudinaryPublicId: result.public_id,
      cloudinaryUrl: result.secure_url,
      thumbnailUrl: thumbnailUrl,
    });
  } catch (error) {
    if (error.message && /invalid signature/i.test(error.message)) {
      const credentialError = new Error(
        'Cloudinary rejected the upload signature. Check the Cloudinary cloud name, API key, and API secret in the server environment.',
      );
      credentialError.status = 502;
      return next(credentialError);
    }
    next(error);
  }
};

const deleteImage = async (req, res, next) => {
  try {
    const { publicId } = req.params;

    if (!publicId.startsWith('mock_pub_') && isCloudinaryConfigured) {
      await cloudinary.uploader.destroy(publicId);
    }

    res.status(200).json({ message: 'Image deleted successfully' });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  uploadParser: upload.single('image'),
  uploadImage,
  deleteImage,
};
