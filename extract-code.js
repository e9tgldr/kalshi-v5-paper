// Extract code blocks from the Kalshi v5 docs page and reconstruct plain text.
const fs = require('fs');
const html = fs.readFileSync(process.argv[2], 'utf8');

function decodeEntities(s) {
  return s
    .replace(/&quot;/g, '"').replace(/&#x27;|&#39;/g, "'").replace(/&lt;/g, '<')
    .replace(/&gt;/g, '>').replace(/&amp;/g, '&').replace(/&nbsp;/g, ' ');
}

// Find all <pre ...><code ...> ... </code></pre> blocks, reconstructing text nodes.
const blocks = [];
const re = /<pre[^>]*>\s*<code[^>]*>([\s\S]*?)<\/code>\s*<\/pre>/g;
let m;
while ((m = re.exec(html)) !== null) {
  let inner = m[1];
  // <br> marks line breaks in Docusaurus code blocks
  inner = inner.replace(/<br\s*\/?>/gi, '\n');
  // Replace every tag with nothing -> adjacent text nodes concatenate to original text
  let text = inner.replace(/<[^>]+>/g, '');
  text = decodeEntities(text);
  blocks.push({ index: m.index, length: text.length, text });
}

// Report heading positions to map blocks to sections
const headings = [];
const hre = /<h[23][^>]*id="([^"]+)"[^>]*>/g;
while ((m = hre.exec(html)) !== null) headings.push({ id: m[1], index: m.index });

console.log('Code blocks found:', blocks.length);
blocks.forEach((b, i) => {
  const section = headings.filter(h => h.index < b.index).pop();
  const firstLine = b.text.split('\n').find(l => l.trim()) || '';
  console.log(`--- block ${i}: chars=${b.length} section=${section ? section.id : '?'} first="${firstLine.trim().slice(0, 80)}"`);
});

blocks.forEach((b, i) => {
  const section = headings.filter(h => h.index < b.index).pop();
  const name = (section && section.id ? section.id : 'block') + '-' + i + '.txt';
  fs.writeFileSync(process.argv[3] + '\\' + name, b.text, 'utf8');
  console.log('saved', name);
});