import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:provider/provider.dart';
import 'package:shepherd_mo/api/api_service.dart';
import 'package:shepherd_mo/models/request.dart';
import 'package:shepherd_mo/providers/ui_provider.dart';
import 'package:shepherd_mo/services/get_login.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shepherd_mo/widgets/empty_data.dart';
import 'package:shepherd_mo/widgets/end_of_line.dart';

class RequestList extends StatefulWidget {
  const RequestList({super.key});

  @override
  _RequestListState createState() => _RequestListState();
}

class _RequestListState extends State<RequestList> {
  static const _pageSize = 10;
  final PagingController<int, RequestModel> _pagingController =
      PagingController(firstPageKey: 1, invisibleItemsThreshold: 1);

  String _searchText = '';
  bool _isAscending = false;
  String _sortBy = 'date';
  int orderBy = 0;

  bool _isMyRequests = false;
  Timer? _debounce;
  int _filterStatus = 0; // 0 - All, 1 - Accepted, 2 - Rejected, 3 - Pending
  final searchController = TextEditingController();
  final searchFocus = FocusNode();

  final String council = dotenv.env['COUNCIL'] ?? '';
  late bool isCouncil = false;

  @override
  void initState() {
    initializeData();
    super.initState();
    _pagingController.addPageRequestListener((pageKey) {
      _fetchPage(pageKey);
    });
  }

  Future<void> initializeData() async {
    final loginInfo = await getLoginInfoFromPrefs();
    setState(() {
      isCouncil = loginInfo!.role == council;
    });
  }

  Future<void> _fetchPage(int pageKey) async {
    try {
      ApiService apiService = ApiService();
      if (_sortBy == 'name') {
        _isAscending ? orderBy = 0 : orderBy = 1;
      } else if (_sortBy == 'date') {
        _isAscending ? orderBy = 6 : orderBy = 7;
      }
      final requests = await apiService.fetchRequests(
        searchKey: _searchText,
        pageNumber: pageKey,
        pageSize: _pageSize,
        filterBy: _filterStatus,
        createdBy: _isMyRequests ? await _getUserId() : null,
        orderBy: orderBy,
      );

      final isLastPage = requests.length < _pageSize;
      if (isLastPage) {
        _pagingController.appendLastPage(requests);
      } else {
        final nextPageKey = pageKey + 1;
        _pagingController.appendPage(requests, nextPageKey);
      }
    } catch (e) {
      print(e);
      _pagingController.error = e;
    }
  }

  Future<String?> _getUserId() async {
    final loginInfo = await getLoginInfoFromPrefs();
    return loginInfo?.id;
  }

  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _searchText = value;
        _refreshList();
      });
    });
  }

  void _toggleRequestView(bool isMyRequests) {
    setState(() {
      _isMyRequests = isMyRequests;
      _refreshList();
    });
  }

  void _toggleSortDirection() {
    setState(() {
      _isAscending = !_isAscending;
      _refreshList();
    });
  }

  void _onSortChanged(String sortBy) {
    setState(() {
      _sortBy = sortBy;
    });
    _refreshList();
  }

  void _onFilterStatusChanged(int? newValue) {
    if (newValue != null) {
      setState(() {
        _filterStatus = newValue;
        _refreshList(); // Refresh the list when the filter changes
      });
    }
  }

  Future<void> _refreshList() async {
    _pagingController.refresh();
  }

  void _unfocus() {
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    final uiProvider = Provider.of<UIProvider>(context);
    bool isDark = uiProvider.themeMode == ThemeMode.dark ||
        (uiProvider.themeMode == ThemeMode.system &&
            MediaQuery.of(context).platformBrightness == Brightness.dark);
    String getSortText(String sortBy) {
      return sortBy == 'date' ? localizations.date : localizations.name;
    }

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          localizations.request,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        backgroundColor: isDark ? Colors.grey[900] : Color(0xFFEEC05C),
        elevation: 2,
      ),
      body: GestureDetector(
        onTap: _unfocus,
        child: Padding(
          padding: EdgeInsets.all(screenHeight * 0.016),
          child: Column(
            children: [
              // My Requests / All Requests Toggle
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  isCouncil
                      ? ToggleButtons(
                          isSelected: [
                            _isMyRequests == false,
                            _isMyRequests == true
                          ],
                          onPressed: (index) {
                            _toggleRequestView(index == 1);
                          },
                          fillColor:
                              isDark ? Colors.grey[700] : Color(0xFFEEC05C),
                          selectedColor: Colors.white,
                          borderColor:
                              isDark ? Colors.grey[700] : Color(0xFFEEC05C),
                          selectedBorderColor:
                              isDark ? Colors.grey[700] : Color(0xFFEEC05C),
                          borderRadius: BorderRadius.circular(15),
                          children: [
                            Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: screenWidth * 0.035),
                              child: Text(localizations.allRequest),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: screenWidth * 0.035),
                              child: Text(localizations.myRequests),
                            ),
                          ],
                        )
                      : SizedBox.shrink(),
                ],
              ),
              SizedBox(height: screenHeight * 0.016),
              // Search, Sort, and Filter Bar
              Container(
                padding: EdgeInsets.all(screenHeight * 0.012),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[800] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                    width: 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: searchController,
                        focusNode: searchFocus,
                        decoration: InputDecoration(
                          labelText: localizations.search,
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    searchController.clear();
                                    _searchText = '';
                                    _refreshList();
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onChanged: _onSearchChanged, // Debounced search input
                      ),
                    ),
                    SizedBox(width: screenWidth * 0.025),
                    PopupMenuButton<String>(
                      initialValue: "date",
                      onSelected: (value) => _onSortChanged(value ?? 'date'),
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'date',
                          child: Text(localizations.date),
                        ),
                        PopupMenuItem(
                          value: 'name',
                          child: Text(localizations.name),
                        ),
                      ],
                      child: Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[800] : Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              getSortText(_sortBy),
                              style: TextStyle(
                                  color: isDark
                                      ? Colors.grey[300]
                                      : Colors.grey[800]),
                            ),
                            Icon(Icons.arrow_drop_down,
                                color: isDark
                                    ? Colors.grey[300]
                                    : Colors.grey[800]),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        _isAscending
                            ? Icons.arrow_upward
                            : Icons.arrow_downward,
                        color: isDark ? Colors.grey[300] : Color(0xFFEEC05C),
                      ),
                      onPressed: _toggleSortDirection,
                    ),
                    SizedBox(width: screenWidth * 0.025),
                    PopupMenuButton<int>(
                      position: PopupMenuPosition
                          .under, // Opens the popup menu below the button
                      initialValue: _filterStatus,
                      onSelected:
                          _onFilterStatusChanged, // Called when an option is selected
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 0,
                          child: Text(localizations.all),
                        ),
                        PopupMenuItem(
                          value: 1,
                          child: Text(localizations.accepted),
                        ),
                        PopupMenuItem(
                          value: 2,
                          child: Text(localizations.rejected),
                        ),
                        PopupMenuItem(
                          value: 3,
                          child: Text(localizations.pending),
                        ),
                      ],
                      icon: Icon(
                        Icons.filter_alt_outlined,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: screenHeight * 0.01),

              // Request List
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async => _refreshList(),
                  child: PagedListView<int, RequestModel>(
                    pagingController: _pagingController,
                    builderDelegate: PagedChildBuilderDelegate<RequestModel>(
                      itemBuilder: (context, request, index) => Container(
                        padding: EdgeInsets.all(screenHeight * 0.012),
                        margin: EdgeInsets.symmetric(
                            vertical: screenHeight * 0.008),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[850] : Colors.white,
                          border: Border.all(
                            color: isDark
                                ? Colors.grey.shade700
                                : Colors.grey.shade300,
                            width: 1.0,
                          ),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            if (!isDark)
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                blurRadius: 8,
                                spreadRadius: 2,
                                offset: const Offset(0, 4),
                              ),
                          ],
                        ),
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            request.title,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: screenHeight * 0.017,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          subtitle: Padding(
                            padding: EdgeInsets.only(top: screenHeight * 0.006),
                            child: Text(
                              request.content,
                              style: TextStyle(
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[700],
                              ),
                            ),
                          ),
                          trailing: Icon(
                            request.isAccepted == true
                                ? Icons.check_circle
                                : request.isAccepted == false
                                    ? Icons.cancel
                                    : Icons.pending,
                            color: request.isAccepted == true
                                ? Colors.green
                                : request.isAccepted == false
                                    ? Colors.red
                                    : Color(0xFFEEC05C),
                          ),
                        ),
                      ),
                      firstPageProgressIndicatorBuilder: (_) =>
                          const Center(child: CircularProgressIndicator()),
                      newPageProgressIndicatorBuilder: (_) =>
                          const Center(child: CircularProgressIndicator()),
                      noItemsFoundIndicatorBuilder: (context) => Center(
                        child: _searchText.isNotEmpty
                            ? EmptyData(
                                noDataMessage: localizations.noResult,
                                message: localizations.godAlwaysByYourSide)
                            : EmptyData(
                                noDataMessage: localizations.noRequest,
                                message: localizations.godAlwaysByYourSide),
                      ),
                      noMoreItemsIndicatorBuilder: (_) => Padding(
                        padding:
                            EdgeInsets.symmetric(vertical: screenHeight * 0.02),
                        child: EndOfListWidget(),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pagingController.dispose();
    _debounce?.cancel();
    super.dispose();
  }
}
