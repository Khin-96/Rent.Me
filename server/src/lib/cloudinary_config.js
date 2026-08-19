const cloudinary = require('cloudinary').v2;

function clean(value) {
  return String(value || '')
    .trim()
    .replace(/^['"]|['"]$/g, '');
}

const config = {
  cloud_name: clean(process.env.CLOUDINARY_CLOUD_NAME),
  api_key: clean(process.env.CLOUDINARY_API_KEY),
  api_secret: clean(process.env.CLOUDINARY_API_SECRET),
};

const isCloudinaryConfigured = Object.values(config).every(
  (value) => value && !value.startsWith('your_'),
);

if (isCloudinaryConfigured) {
  cloudinary.config(config);
}

module.exports = { cloudinary, isCloudinaryConfigured };
