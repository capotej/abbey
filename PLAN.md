# PDF Paper Implementation Plan

1. **Model Creation**
   - Generate Paper model migration
   - Add Active Storage attachment for PDF
   - Add content type validation

2. **Link Creation Logic**
   - Modify LinksController#create to check URL content type
   - Add PDF detection via HEAD request
   - Create Paper instead of Link when PDF detected

3. **Paper Download & Storage**
   - Implement PDF downloading service
   - Handle attachment in Paper model
   - Add error handling for failed downloads

4. **PapersController**
   - Add index action
   - Create view listing papers with download links
   - Add routing

5. **Testing**
   - Write integration test for PDF detection
   - Test both PDF and non-PDF URL cases
   - Verify attachment functionality

6. **Security**
   - Add virus scanning (if needed)
   - Validate file size limits
   - Implement rate limiting

7. **Deployment**
   - Update database schema
   - Add storage configuration
   - Update seed data if needed