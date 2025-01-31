import 'dart:convert';

import 'package:flutter_session_manager/flutter_session_manager.dart';
import "package:http/http.dart" as http;

import 'constants.dart';
import 'entities/auth.dart';
import 'entities/content.dart';
import 'entities/user.dart';

class TabNewsClient {
  final Session session;
  static final http.Client client = http.Client();

  TabNewsClient(this.session);

  Map<String, String> authHeaders() {
    return {
      "Cookie": "session_id=${session.token}"
    };
  }

  static Map<String, String> headers() {
    return {
      "Content-Type": "application/json",
    };
  }

  Future<User> getUser() async {
    var response =
        await client.get(Uri.parse("$baseUrl/user"), headers: authHeaders());

    if (response.statusCode != 200) {
      return Future.error(Exception(response.statusCode));
    }
    var json = jsonDecode(response.body);
    var user = User.fromJson(json);
    return user;
  }

  Future<Content> publishContent(NewContent content) async {
    var response = await client.post(Uri.parse("$baseUrl/contents"),
        headers: authHeaders());

    if (response.statusCode != 201) {
      return Future.error(Exception(response.statusCode));
    }
    var json = jsonDecode(response.body);
    var content = Content.fromJson(json);
    return content;
  }

  static Future<List<Content>> listContents(
      int page, int perPage, Strategy strategy) async {
    var response = await client.get(Uri.parse(
        "$baseUrl/contents?page=$page&per_page=$perPage&strategy=$strategy"));

    if (response.statusCode != 200) {
      return Future.error(Exception(response.statusCode));
    }
    List<dynamic> json = jsonDecode(response.body);
    var contents = List.of(json.map((e) => Content.fromJson(e)));
    return contents;
  }

  static Future<List<Content>> getChildren(Content content) async {
    var response = await client.get(Uri.parse(
        "$baseUrl/contents/${content.owner_username}/${content.slug}/children"));

    if (response.statusCode != 200) {
      return Future.error(Exception(response.statusCode));
    }
    List<dynamic> json = jsonDecode(response.body);
    return List.of(json.map((e) => Content.fromJson(e)));
  }

  static Future<Content> getContent(
      String author, String slug, bool fetchChildren) async {
    var response =
        await client.get(Uri.parse("$baseUrl/contents/$author/$slug"));

    if (response.statusCode != 200) {
      return Future.error(Exception(response.statusCode));
    }
    var json = jsonDecode(response.body);
    var content = Content.fromJson(json);
    if (fetchChildren) {
      content.children = await getChildren(content);
    }
    return content;
  }

  static Future<void> saveSession(Session session) async {
    var sessionManager = SessionManager();
    await sessionManager.set("session", session);
  }

  static Future<Session> login(LoginRequest loginRequest) async {
    var response = await client.post(Uri.parse("$baseUrl/sessions"),
        body: loginRequest.toJson());
    if (response.statusCode != 201) {
      return Future.error(Exception(response.statusCode));
    }
    var json = jsonDecode(response.body);
    var session = Session.fromJson(json);
    return session;
  }

  static Future<void> recoveryByUsername(String username) async {
    var client = http.Client();
    var response = await client.post(Uri.parse("$baseUrl/recovery"),
        body: {"username": username}, headers: headers());
    if (response.statusCode != 201) {
      return Future.error(Exception(response.statusCode));
    }
  }

  static Future<void> recoveryByEmail(String email) async {
    var response = await client.post(Uri.parse("$baseUrl/recovery"),
        body: {"email": email}, headers: headers());
    if (response.statusCode != 201) {
      return Future.error(Exception(response.statusCode));
    }
  }

  Future<void> editProfile(
      {String? username, String? email, required bool notifications}) async {
    var user = await getUser();
    Map<String, dynamic> body = {'notifications': notifications};
    if (username != null) {
      body["username"] = username;
    }
    if (email != null) {
      body["email"] = email;
    }
    var response = await client.patch(
        Uri.parse("$baseUrl/users/${user.username}"),
        headers: authHeaders(),
        body: jsonEncode(body));
    if (response.statusCode != 200) {
      return Future.error(Exception(jsonDecode(response.body)));
    }
  }

  Future<void> upvote(Content content) async {
    var response = await client.post(
      Uri.parse(
        "$baseUrl/contents/${content.owner_username}/${content.slug}/tabcoins",
      ),
      headers: authHeaders(),
      body: {
        "transaction_type": "credit",
      },
    );

    if (response.statusCode != 201) {
      return Future.error(Exception(response.statusCode));
    }
  }

  Future<void> downvote(Content content) async {
    var response = await client.post(
      Uri.parse(
        "$baseUrl/contents/${content.owner_username}/${content.slug}/tabcoins",
      ),
      headers: authHeaders(),
      body: {
        "transaction_type": "debit",
      },
    );

    if (response.statusCode != 201) {
      return Future.error(Exception(response.statusCode));
    }
  }
}

enum Strategy {
  relevant("relevant"),
  newest("new"),
  old("old");

  final String value;

  const Strategy(this.value);

  @override
  String toString() {
    return value;
  }
}
