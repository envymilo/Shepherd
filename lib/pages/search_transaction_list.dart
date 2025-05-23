import 'dart:async';
import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shepherd_mo/api/api_service.dart';
import 'package:shepherd_mo/formatter/custom_currency_format.dart';
import 'package:shepherd_mo/models/transaction.dart';
import 'package:shepherd_mo/providers/ui_provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shepherd_mo/widgets/empty_data.dart';
import 'package:shepherd_mo/widgets/end_of_line.dart';

class TransactionList extends StatefulWidget {
  final String groupId;
  const TransactionList({
    super.key,
    required this.groupId,
  });

  @override
  _TransactionListState createState() => _TransactionListState();
}

class _TransactionListState extends State<TransactionList> {
  static const _pageSize = 10;
  final PagingController<int, Transaction> _pagingController =
      PagingController(firstPageKey: 1, invisibleItemsThreshold: 1);

  String _searchText = '';
  bool _isAscending = false;
  String _sortBy = 'date';
  int orderBy = 0;

  Timer? _debounce;
  String _filterType = "";
  final searchController = TextEditingController();
  final searchFocus = FocusNode();
  late bool isCouncil = false;

  @override
  void initState() {
    super.initState();
    _pagingController.addPageRequestListener((pageKey) {
      _fetchPage(pageKey);
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
      final requests = await apiService.fetchTransactions(
          searchKey: _searchText,
          pageNumber: pageKey,
          pageSize: _pageSize,
          groupId: widget.groupId,
          orderBy: orderBy,
          type: _filterType);

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

  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _searchText = value;
        _refreshList();
      });
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

  void _onFilterStatusChanged(String? newValue) {
    if (newValue != null) {
      setState(() {
        _filterType = newValue;
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
          localizations.transaction,
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
                    PopupMenuButton<String>(
                      position: PopupMenuPosition
                          .under, // Opens the popup menu below the button
                      initialValue: _filterType,
                      onSelected:
                          _onFilterStatusChanged, // Called when an option is selected
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: "",
                          child: Text(localizations.all),
                        ),
                        PopupMenuItem(
                          value: "Từ thiện",
                          child: Text(localizations.donation),
                        ),
                        PopupMenuItem(
                          value: "Chi phí",
                          child: Text(localizations.expense),
                        ),
                        PopupMenuItem(
                          value: "Quỹ vào",
                          child: Text(localizations.fundIn),
                        ),
                        PopupMenuItem(
                          value: "Chi phí công việc",
                          child: Text(localizations.taskCost),
                        ),
                        PopupMenuItem(
                          value: "Hoàn trả công việc",
                          child: Text(localizations.taskRefund),
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
                  child: PagedListView<int, Transaction>(
                    pagingController: _pagingController,
                    builderDelegate: PagedChildBuilderDelegate<Transaction>(
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
                                color: Colors.grey.withOpacity(0.4),
                                blurRadius: 8,
                                spreadRadius: 2,
                                offset: const Offset(0, 4),
                              ),
                          ],
                        ),
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                request.type,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: screenHeight * 0.018,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                              Text(
                                "${widget.groupId == request.groupID ? "+" : "-"}${formatCurrency(request.amount.ceil())} VNĐ",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: screenHeight * 0.016,
                                  color: widget.groupId == request.groupID
                                      ? Colors.green
                                      : Colors.red,
                                ),
                              ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                DateFormat('dd/MM/yyyy HH:mm')
                                    .format(request.date),
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.grey[400]
                                      : Colors.grey[700],
                                ),
                              ),
                              Text(
                                "${localizations.to}: ${request.group.groupName}",
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.grey[400]
                                      : Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                          leading: Icon(
                              request.approvalStatus == "Chờ duyệt"
                                  ? Icons.pending
                                  : Icons.check_circle,
                              color: request.approvalStatus == "Chờ duyệt"
                                  ? Color(0xFFEEC05C)
                                  : Colors.green),
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
                                noDataMessage: localizations.noTransaction,
                                message: localizations.godAlwaysByYourSide),
                      ),
                      noMoreItemsIndicatorBuilder: (_) => EndOfListWidget(),
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
