import { DirectUpload } from "@rails/activestorage"
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    connect() {
        const textarea = this.element;
        if (!textarea) {
            console.error("Textarea element not found!");
            return;
        }

        const hiddenFileInput = document.getElementById('markdown_body_attachments');
        if (!hiddenFileInput) {
            console.error("Hidden file input not found!");
            return;
        }

        const uploadFile = (file) => {
            const url = hiddenFileInput.dataset.directUploadUrl;
            const upload = new DirectUpload(file, url);
            const placeholder = `![Uploading ${file.name}...]()`;

            insertAtCursor(textarea, placeholder);

            upload.create((error, blob) => {
                if (error) {
                    console.error("Upload error:", error);
                    replacePlaceholder(placeholder, `![Error: ${file.name}]()`);
                } else {
                    replacePlaceholder(placeholder, `![${file.name}](${blob.signed_id})`);
                }
            });
        };

        const replacePlaceholder = (placeholder, newText) => {
            textarea.value = textarea.value.replace(placeholder, newText);
        };

        textarea.addEventListener('drop', (event) => {
            event.preventDefault();
            const files = event.dataTransfer.files;
            Array.from(files).forEach(uploadFile);
        });

        textarea.addEventListener('paste', (event) => {
            const items = (event.clipboardData || event.originalEvent.clipboardData).items;
            let hasFiles = false;

            for (const item of items) {
                if (item.kind === 'file') {
                    hasFiles = true;
                    const file = item.getAsFile();
                    uploadFile(file);
                }
            }

            // Only prevent default if files were pasted
            if (hasFiles) {
                event.preventDefault();
            }
        });


        // Helper function to insert text at cursor position in textarea
        function insertAtCursor(textarea, text) {
            let startPos = textarea.selectionStart;
            let endPos = textarea.selectionEnd;
            let currentValue = textarea.value;

            // Check for undefined selectionStart (can happen in some browsers)
            if (typeof startPos === "undefined") {
                startPos = 0;
                endPos = 0;
            }

            textarea.value = currentValue.slice(0, startPos) + text + currentValue.slice(endPos);
            textarea.selectionStart = textarea.selectionEnd = startPos + text.length;
            textarea.focus();
        }
    }
}
