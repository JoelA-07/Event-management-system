const express = require('express');
const router = express.Router();
const { 
  addService,
  addMenu,
  getServicesByCategory,
  getMyServices,
  getMyMenus,
  getAllVendorServices,
  deleteService,
  deleteMenu,
  orderSample,
  getVendorDashboardStats,
  getVendorSampleOrders,
  getEventRecommendations,
} = require('../controllers/vendorController');

router.post('/add', addService);
router.post('/add-menu', addMenu);
router.get('/all', getAllVendorServices);
router.get('/my-services/:vendorId', getMyServices);
router.get('/menus/:vendorId', getMyMenus);
router.get('/stats/:vendorId', getVendorDashboardStats);
router.get('/samples/:vendorId', getVendorSampleOrders);
router.get('/event/:eventType', getEventRecommendations);
router.delete('/delete/:id', deleteService);
router.delete('/menu/:id', deleteMenu);
router.post('/order-sample', orderSample);
router.get('/:category', getServicesByCategory);

module.exports = router;
