const multer = require('multer');
const path = require('path');

// Set storage engine
const storage = multer.diskStorage({
  destination: './uploads/',
  filename: (req, file, cb) => {
    cb(null, file.fieldname + '-' + Date.now() + path.extname(file.originalname));
  },
});

const uploader = multer({
  storage: storage,
  limits: { fileSize: 5000000 }, // 5MB limit
});

const uploadSingle = uploader.single('image'); // 'image' is the key we will use in Flutter
const uploadMultiple = uploader.array('images', 10); // 'images' for portfolios

module.exports = {
  uploadSingle,
  uploadMultiple,
};
