import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/gmail/v1.dart' as gmail;
import 'package:http/http.dart' as http;
import 'message_parser_service.dart';

class GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _client.send(request..headers.addAll(_headers));
  }
}

class GmailService {
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  bool _initialized = false;

  GoogleSignInAccount? _currentUser;
  gmail.GmailApi? _gmailApi;

  Future<bool> authenticate() async {
    try {
      if (!_initialized) {
        await _googleSignIn.initialize();
        _initialized = true;
      }
      // 1. Authenticate user
      _currentUser = await _googleSignIn.authenticate(
        scopeHint: [gmail.GmailApi.gmailReadonlyScope],
      );

      // 2. Request authorization headers for Gmail scope
      final headers = await _googleSignIn.authorizationClient.authorizationHeaders(
        [gmail.GmailApi.gmailReadonlyScope],
        promptIfNecessary: true,
      );

      if (headers == null) return false;

      // 3. Create the API client
      final authClient = GoogleAuthClient(headers);
      _gmailApi = gmail.GmailApi(authClient);
      
      return true;
    } catch (e) {
      print('Error authenticating with Google: $e');
      return false;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    _currentUser = null;
    _gmailApi = null;
  }

  Future<List<ParsedTransaction>> scanBankEmails({int days = 7}) async {
    if (_gmailApi == null) return [];

    try {
      // Create a search query for common bank emails
      final dateThreshold = DateTime.now().subtract(Duration(days: days));
      final dateStr = '${dateThreshold.year}/${dateThreshold.month}/${dateThreshold.day}';
      
      final query = 'subject:(debited OR credited OR transaction OR payment OR UPI OR IMPS OR NEFT) '
                    'after:$dateStr '
                    '(from:hdfcbank.net OR from:icicibank.com OR from:sbi.co.in OR from:axisbank.com '
                    'OR from:kotak.com OR from:paytm.com OR from:phonepe.com OR from:google.com)';

      final response = await _gmailApi!.users.messages.list('me', q: query, maxResults: 20);
      final messages = response.messages;

      if (messages == null || messages.isEmpty) return [];

      List<ParsedTransaction> transactions = [];

      for (var msg in messages) {
        if (msg.id != null) {
          final fullMsg = await _gmailApi!.users.messages.get('me', msg.id!, format: 'full');
          
          final body = _extractBody(fullMsg.payload);
          if (body.isNotEmpty) {
             final parsed = MessageParserService.parseMessage(body);
             if (parsed != null) {
               transactions.add(parsed);
             }
          }
        }
      }

      return transactions;
    } catch (e) {
      print('Error scanning emails: $e');
      return [];
    }
  }

  String _extractBody(gmail.MessagePart? payload) {
    if (payload == null) return '';
    if (payload.parts != null && payload.parts!.isNotEmpty) {
      for (var part in payload.parts!) {
        if (part.mimeType == 'text/plain' && part.body?.data != null) {
          return _decodeBase64Url(part.body!.data!);
        }
      }
      return _extractBody(payload.parts!.first);
    } else if (payload.body?.data != null) {
      return _decodeBase64Url(payload.body!.data!);
    }
    return '';
  }

  String _decodeBase64Url(String base64UrlStr) {
    try {
      var str = base64UrlStr;
      str = str.replaceAll('-', '+').replaceAll('_', '/');
      while (str.length % 4 != 0) {
        str += '=';
      }
      return utf8.decode(base64Decode(str));
    } catch (e) {
      return '';
    }
  }
}
