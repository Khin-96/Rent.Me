const multer = require('multer');
const { cloudinary, isCloudinaryConfigured } = require('../lib/cloudinary_config');

// Multer memory storage configuration for videos
const storage = multer.memoryStorage();
const upload = multer({
  storage,
  limits: { fileSize: 30 * 1024 * 1024 }, // 30MB limit for video files
  fileFilter: (req, file, cb) => {
    if (file.mimetype.startsWith('video/')) {
      cb(null, true);
    } else {
      cb(new Error('Only video files are allowed'), false);
    }
  },
});

// Realistic mock video URLs
const mockPropertyVideos = [
  'https://assets.mixkit.co/videos/preview/mixkit-residential-suburb-houses-aerial-view-4840-large.mp4',
  'https://www.w3schools.com/html/mov_bbb.mp4',
  'https://www.w3schools.com/html/movie.mp4',
];

const uploadVideo = async (req, res, next) => {
  try {
    if (!req.file) {
      return res.status(400).json({ error: 'No video file uploaded' });
    }

    if (!isCloudinaryConfigured) {
      // Return a realistic mock video
      const randomIndex = Math.floor(Math.random() * mockPropertyVideos.length);
      const url = mockPropertyVideos[randomIndex];
      const publicId = `mock_vid_${Date.now()}_${Math.floor(Math.random() * 1000)}`;
      
      // Simulate network delay
      await new Promise((resolve) => setTimeout(resolve, 1500));

      return res.status(200).json({
        cloudinaryPublicId: publicId,
        cloudinaryUrl: url,
        thumbnailUrl: 'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?auto=format&fit=crop&w=400&q=80',
      });
    }

    // Upload video file directly to Cloudinary
    const fileBase64 = `data:${req.file.mimetype};base64,${req.file.buffer.toString('base64')}`;
    const result = await cloudinary.uploader.upload(fileBase64, {
      folder: 'habitathub_listings_videos',
      resource_type: 'video',
    });

    // Create a thumbnail from the video
    const thumbnailUrl = cloudinary.url(result.public_id, {
      resource_type: 'video',
      format: 'jpg',
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

const deleteVideo = async (req, res, next) => {
  try {
    const { publicId } = req.params;

    if (!publicId.startsWith('mock_vid_') && isCloudinaryConfigured) {
      await cloudinary.uploader.destroy(publicId, { resource_type: 'video' });
    }

    res.status(200).json({ message: 'Video deleted successfully' });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  uploadParser: upload.single('video'),
  uploadVideo,
  deleteVideo,
};
