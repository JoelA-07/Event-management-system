const express = require('express');
const router = express.Router();
const { verifyToken } = require('../middleware/auth');
const { 
  addService,
  addServiceWithImage,
  updateService,
  addServiceImages,
  removeServiceImage,
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

router.post('/add', addService);
router.post('/add-with-image', addServiceWithImage);
router.put('/:id', updateService);
router.post('/:id/images', addServiceImages);
router.delete('/:id/images', removeServiceImage);
router.post('/add-menu', addMenu);
router.post('/add-menu-with-image', addMenuWithImage);
router.get('/all', getAllVendorServices);
router.get('/my-services/:vendorId', getMyServices);
router.get('/menus/:vendorId', getMyMenus);
router.get('/menus-public/:vendorId', getMenusPublic);
router.get('/stats/:vendorId', getVendorDashboardStats);
router.get('/samples/:vendorId', getVendorSampleOrders);
router.get('/event/:eventType', getEventRecommendations);
router.delete('/delete/:id', deleteService);
router.delete('/menu/:id', deleteMenu);
router.put('/menu/:id', updateMenu);
router.post('/order-sample', orderSample);
router.get('/:category', getServicesByCategory);

module.exports = router;
