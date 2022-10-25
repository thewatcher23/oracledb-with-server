CREATE OR REPLACE trigger TRG_EDI_TRANSACTIONS
  after insert on PROVA
  for each row
DECLARE
  l_url            VARCHAR2(50) := 'http://server:8080';
  l_http_request   UTL_HTTP.req;
  l_http_response  UTL_HTTP.resp;
BEGIN
  -- Make a HTTP request and get the response.
  l_http_request  := UTL_HTTP.begin_request(l_url);
  UTL_HTTP.SET_HEADER(l_http_request, 'User-Agent', 'Mozilla/4.0');
  l_http_response := UTL_HTTP.get_response(l_http_request);
END TRG_EDI_TRANSACTIONS;