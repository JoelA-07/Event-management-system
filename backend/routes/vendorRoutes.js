const express = require('express');
const router = express.Router();
const { verifyToken, requireRole } = require('../middleware/auth');
const upload = require('../middleware/upload');
const { 
  addService,
  addServiceWithImage,
  updateService,
  addMenu,
  addMenuWithImage,
  updateMenu,
  getServicesByCategory,
  getMyServices,
  getMyMenus,
  getMenusPublic,
  getAllVendorServices,
  deleteService,
  deleteMenu,
  orderSample,
  getVendorDashboardStats,
  getVendorSampleOrders,
  getEventRecommendations,
} = require('../controllers/vendorController');

router.use(verifyToken);

router.post('/add', requireRole(['photographer', 'caterer', 'designer', 'mehendi', 'decorator', 'organizer']), addService);
router.post('/add-with-image', requireRole(['photographer', 'caterer', 'designer', 'mehendi', 'decorator', 'organizer']), upload, addServiceWithImage);
router.put('/:id', requireRole(['photographer', 'caterer', 'designer', 'mehendi', 'decorator', 'organizer']), upload, updateService);
router.post('/add-menu', requireRole(['caterer', 'organizer']), addMenu);
router.post('/add-menu-with-image', requireRole(['caterer', 'organizer']), upload, addMenuWithImage);
router.get('/all', getAllVendorServices);
router.get('/my-services/:vendorId', getMyServices);
router.get('/menus/:vendorId', getMyMenus);
router.get('/menus-public/:vendorId', requireRole(['customer', 'organizer']), getMenusPublic);
router.get('/stats/:vendorId', requireRole(['photographer', 'caterer', 'designer', 'mehendi', 'decorator', 'organizer', 'hall_owner']), getVendorDashboardStats);
router.get('/samples/:vendorId', requireRole(['caterer', 'organizer']), getVendorSampleOrders);
router.get('/event/:eventType', getEventRecommendations);
router.delete('/delete/:id', requireRole(['photographer', 'caterer', 'designer', 'mehendi', 'decorator', 'organizer']), deleteService);
router.delete('/menu/:id', requireRole(['caterer', 'organizer']), deleteMenu);
router.put('/menu/:id', requireRole(['caterer', 'organizer']), upload, updateMenu);
router.post('/order-sample', requireRole(['customer', 'organizer']), orderSample);
router.get('/:category', getServicesByCategory);

module.exports = router;
