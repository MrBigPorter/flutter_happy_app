enum UploadModule {
  kyc('/api/v1/kyc/upload-url'),
  common('api/v1/common/upload-url');

  final String apiPath;
  const UploadModule(this.apiPath);
}