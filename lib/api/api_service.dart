import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shepherd_mo/models/activity.dart';
import 'package:shepherd_mo/models/ceremony.dart';
import 'package:shepherd_mo/models/event.dart';
import 'package:shepherd_mo/models/group.dart';
import 'package:shepherd_mo/models/group_member.dart';
import 'package:shepherd_mo/models/notification.dart';
import 'package:shepherd_mo/models/request.dart';
import 'package:shepherd_mo/models/task.dart';
import 'package:shepherd_mo/models/transaction.dart';
import 'package:shepherd_mo/models/user.dart';

class ApiService {
  final String baseUrl = dotenv.env['API_BASE_URL'] ?? '';

  Future<List<Group>> fetchGroups({
    required String searchKey,
    required int pageNumber,
    required int pageSize,
    String? userId,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/group').replace(queryParameters: {
        'SearchKey': searchKey,
        'PageNumber': pageNumber.toString(),
        'PageSize': pageSize.toString(),
        'UserId': userId,
      });

      // Retrieve token from SharedPreferences
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'token');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token', // Add Bearer token
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> results = data['result'];
        return results.map((json) => Group.fromJson(json)).toList();
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Please log in again.');
      } else if (response.statusCode == 404) {
        throw Exception(
            'Not Found: The requested resource could not be found.');
      } else if (response.statusCode == 500) {
        throw Exception('Server Error: Please try again later.');
      } else {
        throw Exception(
            'Error ${response.statusCode}: ${response.reasonPhrase}');
      }
    } catch (error) {
      throw Exception('Error: $error');
    }
  }

  Future<List<Ceremony>> fetchCeremonies({
    required String searchKey,
    required int pageNumber,
    required int pageSize,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/ceremony').replace(queryParameters: {
        'SearchKey': searchKey,
        'PageNumber': pageNumber.toString(),
        'PageSize': pageSize.toString(),
      });

      // Retrieve token from SharedPreferences
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'token');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token', // Add Bearer token
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> results = data['result'];
        return results.map((json) => Ceremony.fromJson(json)).toList();
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Please log in again.');
      } else if (response.statusCode == 404) {
        throw Exception(
            'Not Found: The requested resource could not be found.');
      } else if (response.statusCode == 500) {
        throw Exception('Server Error: Please try again later.');
      } else {
        throw Exception(
            'Error ${response.statusCode}: ${response.reasonPhrase}');
      }
    } catch (error) {
      throw Exception('Error: $error');
    }
  }

  Future<Ceremony> fetchCeremonyDetail({
    required String id,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/ceremony/$id');

      // Retrieve token from SharedPreferences
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'token');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token', // Add Bearer token
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final Map<String, dynamic> result = data['data'];
        return Ceremony.fromJson(result);
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Please log in again.');
      } else if (response.statusCode == 404) {
        throw Exception(
            'Not Found: The requested resource could not be found.');
      } else if (response.statusCode == 500) {
        throw Exception('Server Error: Please try again later.');
      } else {
        throw Exception(
            'Error ${response.statusCode}: ${response.reasonPhrase}');
      }
    } catch (error) {
      throw Exception('Error: $error');
    }
  }

  Future<Map<DateTime, List<Event>>> fetchCeremoniesCalendar(
      String chosenDate,
      String groupId,
      int calendarTypeEnum,
      String userOnly,
      String getUpcoming) async {
    final url = Uri.parse('$baseUrl/ceremony/calendar');
    Map<DateTime, List<Event>> ceremoniesByDate = {};

    // Set query parameters
    final queryParams = {
      'ChosenDate': chosenDate,
      'GroupId': groupId,
      'CalendarTypeEnum': calendarTypeEnum.toString(),
      'UserOnly': userOnly,
      'GetUpcoming': getUpcoming
    };

    final uriWithParams = url.replace(queryParameters: queryParams);
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');
    try {
      final response = await http.get(
        uriWithParams,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> results = data['data'];
        final ceremonies = results.map((json) => Event.fromJson(json)).toList();
        ceremoniesByDate = {};
        for (Event ceremony in ceremonies) {
          final date = DateTime(ceremony.fromDate!.year,
              ceremony.fromDate!.month, ceremony.fromDate!.day);
          if (ceremoniesByDate[date] == null) {
            ceremoniesByDate[date] = [];
          }
          ceremoniesByDate[date]!.add(ceremony);
        }
        return ceremoniesByDate;
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Please log in again.');
      } else if (response.statusCode == 404) {
        throw Exception(
            'Not Found: The requested resource could not be found.');
      } else if (response.statusCode == 500) {
        throw Exception('Server Error: Please try again later.');
      } else {
        throw Exception(
            'Error ${response.statusCode}: ${response.reasonPhrase}');
      }
    } catch (error) {
      throw Exception('Error: $error');
    }
  }

  Future<List<GroupMember>> fetchGroupMembers(
      {required String searchKey,
      required int pageNumber,
      required int pageSize,
      String? groupId,
      String? orderBy,
      String? role}) async {
    try {
      final url = Uri.parse('$baseUrl/group-user').replace(queryParameters: {
        'SearchKey': searchKey,
        'PageNumber': pageNumber.toString(),
        'PageSize': pageSize.toString(),
        'GroupId': groupId,
        if (orderBy != null) 'OrderBy': orderBy,
        if (role != null) 'Role': role
      });

      // Retrieve token from SharedPreferences
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'token');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token', // Add Bearer token
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> results = data['result'];
        return results.map((json) => GroupMember.fromJson(json)).toList();
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Please log in again.');
      } else if (response.statusCode == 404) {
        throw Exception(
            'Not Found: The requested resource could not be found.');
      } else if (response.statusCode == 500) {
        throw Exception('Server Error: Please try again later.');
      } else {
        throw Exception(
            'Error ${response.statusCode}: ${response.reasonPhrase}');
      }
    } catch (error) {
      throw Exception('Error: $error');
    }
  }

  Future<List<Event>?> fetchEvents({
    String? eventId,
    String? groupId,
    String? ceremonyId,
    DateTime? fromDate,
    DateTime? toDate,
    String? status,
    String? orderBy,
    String? filterBy,
    String? searchKey,
    int? pageNumber,
    int? pageSize,
  }) async {
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');

    final url = Uri.parse('$baseUrl/event');
    final queryParams = {
      if (eventId != null) 'EventId': eventId,
      if (groupId != null) 'GroupId': groupId,
      if (ceremonyId != null) 'CeremonyId': ceremonyId,
      if (fromDate != null) 'FromDate': fromDate.toString(),
      if (toDate != null) 'ToDate': toDate.toString(),
      if (status != null) 'Status': status,
      if (orderBy != null) 'OrderBy': orderBy,
      if (filterBy != null) 'FilterBy': filterBy,
      if (searchKey != null) 'SearchKey': searchKey,
      if (pageNumber != null) 'PageNumber': pageNumber.toString(),
      if (pageSize != null) 'PageSize': pageSize.toString(),
    };
    final uriWithParams = url.replace(queryParameters: queryParams);
    try {
      final response = await http.get(
        uriWithParams,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        List<dynamic> results = body['result'];
        return results.map((json) => Event.fromJson(json)).toList();
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Please log in again.');
      } else if (response.statusCode == 40) {
        throw Exception('Bad Request');
      } else if (response.statusCode == 404) {
        throw Exception(
            'Not Found: The requested resource could not be found.');
      } else if (response.statusCode == 500) {
        throw Exception('Server Error: Please try again later.');
      } else {
        throw Exception("Failed to load event details");
      }
    } catch (error) {
      throw Exception('Error: $error');
    }
  }

  Future<Map<DateTime, List<Event>>> fetchEventsCalendar(
      String chosenDate,
      String groupId,
      int calendarTypeEnum,
      String userOnly,
      String getUpcoming) async {
    final url = Uri.parse('$baseUrl/event/calendar');
    Map<DateTime, List<Event>> eventsByDate = {};

    // Set query parameters
    final queryParams = {
      'ChosenDate': chosenDate,
      'GroupId': groupId,
      'CalendarTypeEnum': calendarTypeEnum.toString(),
      'UserOnly': userOnly,
      'GetUpcoming': getUpcoming
    };

    final uriWithParams = url.replace(queryParameters: queryParams);
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');
    try {
      final response = await http.get(
        uriWithParams,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> results = data['data'];
        final events = results.map((json) => Event.fromJson(json)).toList();
        eventsByDate = {};
        for (Event event in events) {
          final date = DateTime(
              event.fromDate!.year, event.fromDate!.month, event.fromDate!.day);
          if (eventsByDate[date] == null) {
            eventsByDate[date] = [];
          }
          eventsByDate[date]!.add(event);
        }
        return eventsByDate;
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Please log in again.');
      } else if (response.statusCode == 404) {
        throw Exception(
            'Not Found: The requested resource could not be found.');
      } else if (response.statusCode == 500) {
        throw Exception('Server Error: Please try again later.');
      } else {
        throw Exception(
            'Error ${response.statusCode}: ${response.reasonPhrase}');
      }
    } catch (error) {
      throw Exception('Error: $error');
    }
  }

  Future<List<Event>> fetchUpcomingEvents(String chosenDate, String groupId,
      int calendarTypeEnum, String userOnly, String getUpcoming) async {
    final url = Uri.parse('$baseUrl/event/calendar');

    // Set query parameters
    final queryParams = {
      'ChosenDate': chosenDate,
      'GroupId': groupId,
      'CalendarTypeEnum': calendarTypeEnum.toString(),
      'UserOnly': userOnly,
      'GetUpcoming': getUpcoming
    };
    try {
      final uriWithParams = url.replace(queryParameters: queryParams);
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'token');

      final response = await http.get(
        uriWithParams,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> results = data['data'];
        final events = results.map((json) => Event.fromJson(json)).toList();
        return events;
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Please log in again.');
      } else if (response.statusCode == 404) {
        throw Exception(
            'Not Found: The requested resource could not be found.');
      } else if (response.statusCode == 500) {
        throw Exception('Server Error: Please try again later.');
      } else {
        throw Exception(
            'Error ${response.statusCode}: ${response.reasonPhrase}');
      }
    } catch (error) {
      throw Exception('Error: $error');
    }
  }

  Future<List<Activity>> fetchUpcomingActivities(
      String chosenDate,
      String groupId,
      int calendarTypeEnum,
      String userOnly,
      String getUpcoming) async {
    final url = Uri.parse('$baseUrl/activity/calendar');
    try {
      // Set query parameters
      final queryParams = {
        'ChosenDate': chosenDate,
        'GroupId': groupId,
        'CalendarTypeEnum': calendarTypeEnum.toString(),
        'UserOnly': userOnly,
        'GetUpcoming': getUpcoming
      };

      final uriWithParams = url.replace(queryParameters: queryParams);
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'token');

      final response = await http.get(
        uriWithParams,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> results = data['data'];
        final activities =
            results.map((json) => Activity.fromJson(json)).toList();
        return activities;
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Please log in again.');
      } else if (response.statusCode == 404) {
        throw Exception(
            'Not Found: The requested resource could not be found.');
      } else if (response.statusCode == 500) {
        throw Exception('Server Error: Please try again later.');
      } else {
        throw Exception(
            'Error ${response.statusCode}: ${response.reasonPhrase}');
      }
    } catch (error) {
      throw Exception('Error: $error');
    }
  }

  Future<List<RequestModel>> fetchRequests({
    required String searchKey,
    required int pageNumber,
    required int pageSize,
    String? groupId,
    String? type,
    String? to,
    String? createdBy,
    int? orderBy,
    int? filterBy,
  }) async {
    // Construct query parameters
    final Map<String, String> queryParams = {
      'SearchKey': searchKey,
      'PageNumber': pageNumber.toString(),
      'PageSize': pageSize.toString(),
      if (groupId != null) 'GroupId': groupId,
      if (type != null) 'Type': type,
      if (to != null) 'To': to,
      if (createdBy != null) 'CreatedBy': createdBy,
      if (orderBy != null) 'OrderBy': orderBy.toString(),
      if (filterBy != null) 'FilterBy': filterBy.toString(),
    };

    // Build URI with query parameters
    final uri = Uri.parse('$baseUrl/request/GetRequests')
        .replace(queryParameters: queryParams);
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');
    try {
      // Send GET request
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      // Check if the request was successful
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> results = data['result'];
        return results.map((json) => RequestModel.fromJson(json)).toList();
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Please log in again.');
      } else if (response.statusCode == 404) {
        throw Exception(
            'Not Found: The requested resource could not be found.');
      } else if (response.statusCode == 500) {
        throw Exception('Server Error: Please try again later.');
      } else {
        throw Exception(
            'Error ${response.statusCode}: ${response.reasonPhrase}');
      }
    } catch (error) {
      throw Exception('Error: $error');
    }
  }

  Future<void> fetchAndCompareGroupRoles(String? userId) async {
    if (userId == '') userId = null;
    try {
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'token');

      final response = await http.get(
        Uri.parse(
            '$baseUrl/user/GetUserRole${userId != null ? '?userId=$userId' : ''}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newGroupRoles = jsonEncode(data['data']);

        // Get stored data from SharedPreferences
        SharedPreferences prefs = await SharedPreferences.getInstance();
        String? cachedGroupRoles = prefs.getString('loginUserGroups');

        // Compare with cached data
        if (cachedGroupRoles != newGroupRoles) {
          // Data has changed, so update SharedPreferences
          await prefs.setString('loginUserGroups', newGroupRoles);
          print('Group roles updated in SharedPreferences');
        } else {
          print('No changes in group roles data');
        }
      } else {
        print('Failed to fetch group roles from API');
      }
    } catch (e) {
      print('Error fetching group roles: $e');
    }
  }

  Future<List<Activity>?> fetchActivities({
    String? eventId,
    String? groupId,
    DateTime? startTime,
    DateTime? endTime,
    String? status,
    String? orderBy,
    String? filterBy,
    String? searchKey,
    int? pageNumber,
    int? pageSize,
  }) async {
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');

    final url = Uri.parse('$baseUrl/activity');
    final queryParams = {
      if (eventId != null) 'EventId': eventId,
      if (groupId != null) 'GroupId': groupId,
      if (startTime != null) 'StartTime': startTime.toString(),
      if (endTime != null) 'EndTime': endTime.toString(),
      if (status != null) 'Status': status,
      if (orderBy != null) 'OrderBy': orderBy,
      if (filterBy != null) 'FilterBy': filterBy,
      if (searchKey != null) 'SearchKey': searchKey,
      if (pageNumber != null) 'PageNumber': pageNumber.toString(),
      if (pageSize != null) 'PageSize': pageSize.toString(),
    };
    try {
      final uri = url.replace(queryParameters: queryParams);
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        List<dynamic> results = body['result'];
        return results.map((json) => Activity.fromJson(json)).toList();
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Please log in again.');
      } else if (response.statusCode == 40) {
        throw Exception('Bad Request');
      } else if (response.statusCode == 404) {
        throw Exception(
            'Not Found: The requested resource could not be found.');
      } else if (response.statusCode == 500) {
        throw Exception('Server Error: Please try again later.');
      } else {
        throw Exception("Failed to load event details");
      }
    } catch (error) {
      throw Exception('Error: $error');
    }
  }

  Future<Map<DateTime, List<Activity>>> fetchActivitiesCalendar(
      String chosenDate,
      String? groupId,
      int calendarTypeEnum,
      String userOnly,
      String getUpcoming) async {
    final url = Uri.parse('$baseUrl/activity/calendar');
    Map<DateTime, List<Activity>> activitiesByDate = {};

    // Set query parameters
    final queryParams = {
      'ChosenDate': chosenDate,
      if (groupId != null) 'GroupId': groupId,
      'CalendarTypeEnum': calendarTypeEnum.toString(),
      'UserOnly': userOnly,
      'GetUpcoming': getUpcoming
    };

    final uriWithParams = url.replace(queryParameters: queryParams);
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');
    try {
      final response = await http.get(
        uriWithParams,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> results = data['data'];
        final activities =
            results.map((json) => Activity.fromJson(json)).toList();
        activitiesByDate = {};
        for (Activity activity in activities) {
          if (activity.startTime != null) {
            final date = DateTime(activity.startTime!.year,
                activity.startTime!.month, activity.startTime!.day);
            if (activitiesByDate[date] == null) {
              activitiesByDate[date] = [];
            }

            activitiesByDate[date]!.add(activity);
          }
        }
        return activitiesByDate;
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Please log in again.');
      } else if (response.statusCode == 404) {
        throw Exception(
            'Not Found: The requested resource could not be found.');
      } else if (response.statusCode == 500) {
        throw Exception('Server Error: Please try again later.');
      } else {
        throw Exception(
            'Error ${response.statusCode}: ${response.reasonPhrase}');
      }
    } catch (error) {
      throw Exception('Error: $error');
    }
  }

  Future<(int, List<Task>)> fetchTasks({
    required String searchKey,
    required int pageNumber,
    required int pageSize,
    String? groupId,
    String? activityId,
    String? eventId,
    String? userId,
    String? groupPresetId,
    String? status,
  }) async {
    // Construct query parameters
    final Map<String, String> queryParams = {
      'SearchKey': searchKey,
      'PageNumber': pageNumber.toString(),
      'PageSize': pageSize.toString(),
      if (groupId != null) 'GroupId': groupId,
      if (activityId != null) 'ActivityId': activityId,
      if (eventId != null) 'EventId': eventId,
      if (userId != null) 'UserId': userId,
      if (groupPresetId != null) 'GroupPresetID': groupPresetId.toString(),
      if (status != null) 'Status': status.toString(),
    };

    // Build URI with query parameters
    final uri =
        Uri.parse('$baseUrl/task/group').replace(queryParameters: queryParams);
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');
    try {
      // Send GET request
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      // Check if the request was successful
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> results = data['result'];
        final int totalCount = data['pagination']['totalCount'] ?? 0;
        return (
          totalCount,
          results.map((json) => Task.fromJson(json)).toList()
        );
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Please log in again.');
      } else if (response.statusCode == 404) {
        throw Exception(
            'Not Found: The requested resource could not be found.');
      } else if (response.statusCode == 500) {
        throw Exception('Server Error: Please try again later.');
      } else {
        throw Exception(
            'Error ${response.statusCode}: ${response.reasonPhrase}');
      }
    } catch (error) {
      throw Exception('Error: $error');
    }
  }

  Future<Task> fetchTaskDetail({
    required String id,
  }) async {
    // Build URI with query parameters
    final uri = Uri.parse('$baseUrl/task/$id');
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');
    try {
      // Send GET request
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      // Check if the request was successful
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final Map<String, dynamic> results = data['data'];
        return Task.fromJson(results);
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Please log in again.');
      } else if (response.statusCode == 404) {
        throw Exception(
            'Not Found: The requested resource could not be found.');
      } else if (response.statusCode == 500) {
        throw Exception('Server Error: Please try again later.');
      } else {
        throw Exception(
            'Error ${response.statusCode}: ${response.reasonPhrase}');
      }
    } catch (error) {
      throw Exception('Error: $error');
    }
  }

  Future<bool> updateTaskStatus(Task task, String newStatus) async {
    final url = Uri.parse('$baseUrl/task/${task.id}');
    // Prepare the request body with only the `status` field
    final Map<String, dynamic> requestBody = {
      "status": newStatus,
    };
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');
    try {
      final response = await http.patch(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        print('Update Successfully');
        return true;
      } else {
        print(
            'Failed to update task status: ${response.statusCode} ${response.body}');
        return false;
      }
    } catch (error) {
      print('Error updating task status: $error');
      return false;
    }
  }

  Future<(bool, String?)> createTask(Task task) async {
    final url = Uri.parse('$baseUrl/task');
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');
    try {
      print(jsonEncode(task.toJson()));
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(task.toJson()),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = jsonDecode(response.body);
        final bool success = responseBody['success'] as bool;
        final String? message = responseBody['message'] as String?;
        if (success == true) {
          print('Create Successfully');
          return (true, "");
        } else {
          if (message != null) {
            return (false, message);
          } else {
            return (false, null);
          }
        }
      } else {
        return (false, null);
      }
    } catch (error) {
      print('Error creating task: $error');
      return (false, error.toString());
    }
  }

  Future<(bool, String?)> updateTask(Task task) async {
    final url = Uri.parse('$baseUrl/task/${task.id}');
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');

    try {
      task.userId ??= "00000000-0000-0000-0000-000000000000";
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(task.toJson()),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = jsonDecode(response.body);
        final bool success = responseBody['success'] as bool;
        final String? message = responseBody['message'] as String?;
        if (success == true) {
          return (true, "");
        } else {
          if (message != null) {
            return (false, message);
          } else {
            return (false, null);
          }
        }
      } else {
        return (false, null);
      }
    } catch (error) {
      print('Error updating task: $error');
      return (false, error.toString());
    }
  }

  Future<bool> confirmTask(String taskId, bool isConfirmed) async {
    final url = Uri.parse('$baseUrl/task/confirm');
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');

    try {
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'taskId': taskId,
          'isConfirmed': isConfirmed,
        }),
      );

      if (response.statusCode == 200) {
        print('Update Successfully');
        return true;
      } else {
        print(
            'Failed to update task status: ${response.statusCode} ${response.body}');
        return false;
      }
    } catch (error) {
      print('Error updating task status: $error');
      return false;
    }
  }

  Future<(bool, String?)> firstUpdate(Map<String, dynamic> user) async {
    final url = Uri.parse('$baseUrl/user/FirstUpdate');
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');
    print(jsonEncode(user));
    try {
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(user),
      );

      final Map<String, dynamic> responseBody = jsonDecode(response.body);
      if (response.statusCode == 200) {
        final bool success = responseBody['success'] as bool;
        final String? message = responseBody['message'] as String?;
        if (success) {
          final data = responseBody['data'];
          final token = data['token'];
          await storage.write(key: 'token', value: token);
          return (true, null);
        } else {
          return (false, message);
        }
      } else {
        return (false, null);
      }
    } catch (error) {
      print('Error updating user: $error');
      return (false, null);
    }
  }

  Future<(bool, String?)> updateUser(User user) async {
    final url = Uri.parse('$baseUrl/user');
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');
    print(jsonEncode(user.toJson()));
    try {
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(user.toJson()),
      );

      final Map<String, dynamic> responseBody = jsonDecode(response.body);
      if (response.statusCode == 200) {
        final bool success = responseBody['success'] as bool;
        final String? message = responseBody['message'] as String?;
        if (success) {
          final user = responseBody['data'];
          final SharedPreferences prefs = await SharedPreferences.getInstance();
          prefs.setString('loginInfo', jsonEncode(user));
          return (true, null);
        } else {
          return (false, message);
        }
      } else {
        return (false, null);
      }
    } catch (error) {
      print('Error updating task status: $error');
      return (false, null);
    }
  }

  Future<(bool, String)> changePassword(
      String id, String oldPassword, String newPassword) async {
    final url = Uri.parse('$baseUrl/user/UpdatePassword');
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');

    try {
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(
          {'id': id, 'oldPassword': oldPassword, 'newPassword': newPassword},
        ),
      );

      final Map<String, dynamic> responseBody = jsonDecode(response.body);
      if (response.statusCode == 200) {
        final bool success = responseBody['success'] as bool;
        final String message = responseBody['message'] as String;
        if (success) {
          print('Update Successfully');
          return (true, "");
        } else {
          final error = responseBody['message'] as String;
          print(
              'Failed to update task status: ${response.statusCode} ${response.body}');
          return (false, message);
        }
      } else {
        return (false, "");
      }
    } catch (error) {
      print('Error updating task status: $error');
      return (false, "");
    }
  }

  Future<User?> getUserDetails(String id) async {
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');
    try {
      final Map<String, String> queryParams = {
        'id': id,
      };
      final uri = Uri.parse('$baseUrl/user/Detail')
          .replace(queryParameters: queryParams);
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final result = data['data'];
        final user = User.fromJson(result);
        return user;
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Please log in again.');
      } else if (response.statusCode == 404) {
        throw Exception(
            'Not Found: The requested resource could not be found.');
      } else if (response.statusCode == 500) {
        throw Exception('Server Error: Please try again later.');
      } else {
        throw Exception(
            'Error ${response.statusCode}: ${response.reasonPhrase}');
      }
    } catch (error) {
      throw Exception('Error fetching requests: $error');
    }
  }

  Future<void> sendDeviceId(String userId, String deviceId) async {
    final url = Uri.parse('$baseUrl/user-device');
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(
          {
            'userId': userId,
            'deviceId': deviceId,
          },
        ),
      );

      final Map<String, dynamic> responseBody = jsonDecode(response.body);
      if (response.statusCode == 200) {
        final bool success = responseBody['success'] as bool;
        final String message = responseBody['message'] as String;
        if (success) {
          print('Create DeviceId Successfully');
          return;
        } else {
          print('Failed to update task status: $message');
          return;
        }
      } else {
        return;
      }
    } catch (error) {
      print('Error creating deviceId: $error');
      return;
    }
  }

  Future<void> deleteDeviceId(String deviceId) async {
    final url = Uri.parse('$baseUrl/user-device?deviceId=$deviceId');
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');
    try {
      final response = await http.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final Map<String, dynamic> responseBody = jsonDecode(response.body);
      if (response.statusCode == 200) {
        final bool success = responseBody['success'] as bool;
        if (success) {
          print('Delete DeviceId Successfully');
          return;
        } else {
          print('Failed to update task status');
          return;
        }
      } else {
        return;
      }
    } catch (error) {
      print('Error deleting deviceId: $error');
      return;
    }
  }

  Future<List<NotificationModel>> fetchNotifications({
    String? searchKey,
    required int pageNumber,
    required int pageSize,
    bool? isRead,
    String? type,
  }) async {
    // Construct query parameters
    final Map<String, String> queryParams = {};

    // Conditionally add 'SearchKey' if searchKey is not null
    if (searchKey != null) {
      queryParams['SearchKey'] = searchKey;
    }

    if (isRead != null) {
      queryParams['IsRead'] = isRead.toString();
    }

    if (type != null) {
      queryParams['Type'] = type;
    }

    // Add PageNumber and PageSize parameters
    queryParams['PageNumber'] = pageNumber.toString();
    queryParams['PageSize'] = pageSize.toString();

    // Build URI with query parameters
    final uri = Uri.parse('$baseUrl/notification')
        .replace(queryParameters: queryParams);
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');
    try {
      // Send GET request
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      // Check if the request was successful
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> results = data['result'];
        return results.map((json) => NotificationModel.fromJson(json)).toList();
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Please log in again.');
      } else if (response.statusCode == 404) {
        throw Exception(
            'Not Found: The requested resource could not be found.');
      } else if (response.statusCode == 500) {
        throw Exception('Server Error: Please try again later.');
      } else {
        throw Exception(
            'Error ${response.statusCode}: ${response.reasonPhrase}');
      }
    } catch (error) {
      throw Exception('Error fetching requests: $error');
    }
  }

  Future<(int, bool)> fetchUnreadNoti() async {
    // Build URI with query parameters
    final uri = Uri.parse('$baseUrl/notification/GetUnread');
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');
    try {
      // Send GET request
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      // Check if the request was successful
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final data = body['data'];
        final unread = data['unread'] as int;
        final haveUnread = data['haveUnread'] as bool;
        return (unread, haveUnread);
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Please log in again.');
      } else if (response.statusCode == 404) {
        throw Exception(
            'Not Found: The requested resource could not be found.');
      } else if (response.statusCode == 500) {
        throw Exception('Server Error: Please try again later.');
      } else {
        throw Exception(
            'Error ${response.statusCode}: ${response.reasonPhrase}');
      }
    } catch (error) {
      throw Exception('Error fetching requests: $error');
    }
  }

  Future<void> readNoti(String id, bool isRead) async {
    final url = Uri.parse('$baseUrl/notification/ReadOne/$id');
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');

    try {
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: isRead.toString(),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = jsonDecode(response.body);
        final bool success = responseBody['success'] as bool;
        final String? message = responseBody['message'] as String?;
        print(message);
      }
    } catch (error) {
      print('Error updating noti: $error');
    }
  }

  Future<void> readAllNoti() async {
    final url = Uri.parse('$baseUrl/notification/ReadAll');
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');

    try {
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = jsonDecode(response.body);
        final bool success = responseBody['success'] as bool;
        final String? message = responseBody['message'] as String?;
        print(message);
      }
    } catch (error) {
      print('Error updating noti: $error');
    }
  }

  Future<void> deleteNoti(String id) async {
    final url = Uri.parse('$baseUrl/notification/UserDeleteOne/$id');
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');

    try {
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = jsonDecode(response.body);
        final bool success = responseBody['success'] as bool;
        final String? message = responseBody['message'] as String?;
        print(message);
      }
    } catch (error) {
      print('Error updating noti: $error');
    }
  }

  Future<List<Transaction>> fetchTransactions({
    required String searchKey,
    required int pageNumber,
    required int pageSize,
    String? groupId,
    String? type,
    int? orderBy,
  }) async {
    // Construct query parameters
    final Map<String, String> queryParams = {
      'SearchKey': searchKey,
      'PageNumber': pageNumber.toString(),
      'PageSize': pageSize.toString(),
      if (groupId != null) 'GroupId': groupId,
      if (type != null) 'Type': type,
      if (orderBy != null) 'OrderBy': orderBy.toString(),
      if (type != null && type.isNotEmpty) 'Type': type,
    };

    // Build URI with query parameters
    final uri =
        Uri.parse('$baseUrl/transaction').replace(queryParameters: queryParams);
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');
    try {
      // Send GET request
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      // Check if the request was successful
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> results = data['result'];
        return results.map((json) => Transaction.fromJson(json)).toList();
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Please log in again.');
      } else if (response.statusCode == 404) {
        throw Exception(
            'Not Found: The requested resource could not be found.');
      } else if (response.statusCode == 500) {
        throw Exception('Server Error: Please try again later.');
      } else {
        throw Exception(
            'Error ${response.statusCode}: ${response.reasonPhrase}');
      }
    } catch (error) {
      throw Exception('Error: $error');
    }
  }

  Future<String?> uploadImage(File imageFile) async {
    try {
      // Create multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/image/Upload'),
      );
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'token');
      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      // Add the file to the request
      var multipartFile = await http.MultipartFile.fromPath(
        'file', // field name matching API expectation
        imageFile.path,
      );
      request.files.add(multipartFile);

      // Send the request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      // Check if the request was successful
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final String? data = body['data'];
        return data;
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Please log in again.');
      } else if (response.statusCode == 404) {
        throw Exception(
            'Not Found: The requested resource could not be found.');
      } else if (response.statusCode == 500) {
        throw Exception('Server Error: Please try again later.');
      } else {
        return null;
      }
    } catch (error) {
      throw Exception('Error: $error');
    }
  }
}
