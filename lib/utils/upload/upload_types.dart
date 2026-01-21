enum UploadModule {
  kyc('/api/v1/kyc/ocr-scan'),
  common('api/v1/common/upload-url'),
  chat('/api/v1/chat/upload-token');

  final String apiPath;
  const UploadModule(this.apiPath);
}