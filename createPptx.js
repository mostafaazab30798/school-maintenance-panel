// Edge Function (Node.js) باستخدام PptxGenJS لإنشاء عرض باوربوينت ديناميكي
import PptxGenJS from 'pptxgenjs';
import formidable from 'formidable';
import { readFile } from 'fs/promises';
import http from 'http';

const server = http.createServer(async (req, res) => {
  if (req.method === 'POST') {
    const form = formidable({ multiples: true });

    form.parse(req, async (err, fields, files) => {
      if (err) {
        res.writeHead(500);
        res.end('Error parsing form');
        return;
      }

      const pptx = new PptxGenJS();

      // الشريحة الأولى - اسم المدرسة
      const schoolName = fields.schoolName || 'تقرير مدرسة';
      const firstSlide = pptx.addSlide();
      firstSlide.addText(schoolName, { x: 1, y: 1, fontSize: 24, bold: true });

      // بناء الشرائح لكل ملاحظة
      const notes = Object.keys(fields)
        .filter((key) => key.startsWith('notes[') && key.endsWith('][note]'))
        .map((key) => {
          const index = key.match(/notes\[(\d+)\]/)[1];
          return {
            note: fields[`notes[${index}][note]`],
            action: fields[`notes[${index}][action]`],
            index,
          };
        });

      for (const { note, action, index } of notes) {
        const slide = pptx.addSlide();
        slide.addText(note, { x: 0.5, y: 0.5, fontSize: 18, bold: true });
        slide.addText(action, { x: 0.5, y: 1.2, fontSize: 16 });

        const imageFiles = files[`notes[${index}][images][]`];
        const imageList = Array.isArray(imageFiles) ? imageFiles : [imageFiles];

        const total = imageList.length;
        if (total > 0) {
          const rows = Math.ceil(total / 2);
          const imageWidth = 4;
          const imageHeight = 3;
          let x = 0.5;
          let y = 2;

          for (let i = 0; i < total; i++) {
            const file = imageList[i];
            const data = await readFile(file.filepath);
            slide.addImage({ data: data.toString('base64'), x, y, w: imageWidth, h: imageHeight });

            if (x >= 5) {
              x = 0.5;
              y += imageHeight + 0.3;
            } else {
              x += imageWidth + 0.3;
            }
          }
        }
      }

      const buf = await pptx.write('nodebuffer');

      res.writeHead(200, {
        'Content-Disposition': `attachment; filename="${schoolName}.pptx"`,
        'Content-Type': 'application/vnd.openxmlformats-officedocument.presentationml.presentation'
      });
      res.end(buf);
    });
  } else {
    res.writeHead(405);
    res.end('Method Not Allowed');
  }
});

server.listen(3000, () => {
  console.log('Edge function listening on port 3000');
});
