const fs = require('fs');
let c = fs.readFileSync('src/app/page.tsx', 'utf8');

c = c.replace(/<Users size=\{\d+\}\/>/g, '<Groups fontSize="small" />');
c = c.replace(/<Clock3 size=\{\d+\}\/>/g, '<Schedule fontSize="small" />');
c = c.replace(/<StarIcon size=\{\d+\} fill="currentColor"\/>/g, '<Star fontSize="small" sx={{ color: "var(--warning)" }} />');
c = c.replace(/<Award size=\{\d+\}\/>/g, '<EmojiEvents fontSize="small" />');
c = c.replace(/<SearchIcon size=\{\d+\}\/>/g, '<Search fontSize="small" />');
c = c.replace(/<BookOpen size=\{\d+\}\/>/g, '<MenuBook fontSize="small" />');
c = c.replace(/<Atom size=\{\d+\}\/>/g, '<Science fontSize="small" />');
c = c.replace(/<Plus size=\{\d+\}\/>/g, '<Add fontSize="small" />');
c = c.replace(/<CheckIcon size=\{\d+\}\/>/g, '<Check fontSize="small" />');
c = c.replace(/<VideoIcon size=\{\d+\}\/>/g, '<VideoLibrary fontSize="small" />');
c = c.replace(/<NotebookPen size=\{\d+\}\/>/g, '<EditNote fontSize="small" />');
c = c.replace(/<Trophy size=\{\d+\}\/>/g, '<EmojiEvents fontSize="small" />');
c = c.replace(/<ShieldCheck size=\{\d+\}\/>/g, '<Security fontSize="small" />');
c = c.replace(/<MessageCircleQuestion size=\{\d+\}\/>/g, '<HelpIcon fontSize="small" />');
c = c.replace(/<ChevronRightIcon size=\{\d+\}\/>/g, '<ChevronRight fontSize="small" />');
c = c.replace(/<ChevronLeftIcon size=\{\d+\}\/>/g, '<ChevronLeft fontSize="small" />');

fs.writeFileSync('src/app/page.tsx', c);
console.log('Done');
