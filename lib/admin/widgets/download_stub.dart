/// Saves a text file. Only the admin web supports this.
void downloadTextFile(String fileName, String content, {String mime = 'text/csv'}) {
  throw UnsupportedError('Downloads are only available in the admin web');
}
