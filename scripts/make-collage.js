const { createCanvas, loadImage } = require('canvas');
const fs = require('fs');

async function createCollage() {
  const images = [
    '/root/.openclaw/media/inbound/80120015-cf7f-4eae-ac4c-69f1f339adcb.jpg',
    '/root/.openclaw/media/inbound/143d9a2d-2240-407e-bbdc-6762a1a14b0b.jpg',
    '/root/.openclaw/media/inbound/c26fdae3-29ae-4cfe-a939-d346dedab8c3.jpg'
  ];

  // 9:16 ratio = 1080x1920
  const canvas = createCanvas(1080, 1920);
  const ctx = canvas.getContext('2d');

  // No gap - photos touch each other
  const cellWidth = canvas.width;
  const cellHeight = canvas.height / 3;

  for (let i = 0; i < images.length; i++) {
    try {
      const img = await loadImage(images[i]);
      
      const imgAspect = img.width / img.height;
      const cellAspect = cellWidth / cellHeight;
      
      // Aspect-fit (no cropping)
      let drawWidth, drawHeight, dx, dy;
      
      const yPos = i * cellHeight;
      
      if (imgAspect > cellAspect) {
        // Image is wider - fit to width
        drawWidth = cellWidth;
        drawHeight = drawWidth / imgAspect;
        dx = 0;
        dy = yPos + (cellHeight - drawHeight) / 2;
      } else {
        // Image is taller - fit to height
        drawHeight = cellHeight;
        drawWidth = drawHeight * imgAspect;
        dy = yPos;
        dx = (cellWidth - drawWidth) / 2;
      }
      
      ctx.drawImage(img, dx, dy, drawWidth, drawHeight);
      
    } catch (e) {
      console.error('Error loading image', i, e);
    }
  }

  const buffer = canvas.toBuffer('image/jpeg', { quality: 1.0 });
  fs.writeFileSync('/root/.openclaw/workspace/collage-9-16.jpg', buffer);
  console.log('Collage created! No gaps');
}

createCollage();
