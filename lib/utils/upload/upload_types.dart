enum UploadModule {
  kyc('/api/v1/kyc/ocr-scan'),
  common('api/v1/common/upload-url');

  final String apiPath;
  const UploadModule(this.apiPath);
}