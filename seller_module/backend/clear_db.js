const mongoose = require('mongoose');
const Item = require('./models/Item');
const dotenv = require('dotenv');

dotenv.config();

mongoose.connect(process.env.MONGO_URI)
  .then(async () => {
    console.log("Connected to MongoDB.");
    const result = await Item.deleteMany({});
    console.log(`Deleted ${result.deletedCount} items.`);
    process.exit(0);
  })
  .catch(err => {
    console.error(err);
    process.exit(1);
  });
