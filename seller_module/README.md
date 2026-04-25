# 📦 CampusCart Seller Module

This module contains the complete backend and frontend logic for the Seller part of the CampusCart application.

## 📁 Structure
- `/backend`: Express API with MongoDB & Cloudinary integration.
- `/frontend`: React Native screens and API client.

## 🚀 Getting Started

### Backend
1. Go to `seller_module/backend`.
2. Run `npm install`.
3. Create a `.env` file with:
   ```
   PORT=5000
   MONGO_URI=your_mongodb_uri
   JWT_SECRET=your_secret
   CLOUDINARY_CLOUD_NAME=your_name
   CLOUDINARY_API_KEY=your_key
   CLOUDINARY_API_SECRET=your_secret
   ```
4. Run `npm start`.

### Frontend
1. Go to `seller_module/frontend`.
2. Run `npm install`.
3. Update `src/api/client.js` with your machine's IP address.
4. Integrate screens into your `AppNavigator.js`.

## ✨ Features
- Item CRUD (Create, Read, Update, Delete)
- Image Upload to Cloudinary
- JWT Authentication
- Mark Item as SOLD
