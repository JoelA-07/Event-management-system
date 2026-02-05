const express = require('express');
const router = express.Router();
const { 
    addService, 
    getServicesByCategory ,
    getMyServices ,
    getAllVendorServices , 
    deleteService } = require('../controllers/vendorController');
const { orderSample } = require('../controllers/vendorController');

router.post('/add', addService);
router.get('/:category', getServicesByCategory);
router.get('/my-services/:vendorId', getMyServices);
router.delete('/delete/:id', deleteService);
router.get('/all', getServicesByCategory); // Existing (by category)
router.get('/list/all', getAllVendorServices); // New (for Organizer)
router.post('/order-sample', orderSample);

module.exports = router;