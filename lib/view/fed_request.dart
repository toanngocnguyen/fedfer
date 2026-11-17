class FedRequest {
  FedRequest();

  String originRequest = '';
  String path = '/';
  Map<String, String> queryParams = {};

  void setRequestString(String requestString) {
    originRequest = requestString;
    int questionPlace = requestString.indexOf('?');

    queryParams.clear();

    if (questionPlace > 0) {
      path = originRequest.substring(0, questionPlace);

      int ampersandPlace = requestString.indexOf('&', questionPlace);

      if (ampersandPlace <= 0) ampersandPlace = requestString.length;

      int lastAmpersandPlace = questionPlace;

      while (ampersandPlace > 0 && lastAmpersandPlace + 1 <= requestString.length - 1) {
        int equalPlace = requestString.indexOf('=', lastAmpersandPlace + 1);

        if (equalPlace <= 0) break;

        if (lastAmpersandPlace + 1 <= equalPlace - 1) {
          if (equalPlace + 1 <= ampersandPlace - 1) {
            queryParams[requestString.substring(lastAmpersandPlace + 1, equalPlace)] = requestString
                .substring(equalPlace + 1, ampersandPlace);
          } else {
            queryParams[requestString.substring(lastAmpersandPlace + 1, equalPlace)] = '';
          }
        }

        lastAmpersandPlace = ampersandPlace;
        if (ampersandPlace + 1 >= requestString.length) break;
        ampersandPlace = requestString.indexOf('&', ampersandPlace + 1);
      }
    } else {
      path = '';
    }
  }
}
