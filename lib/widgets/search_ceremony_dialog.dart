import 'dart:async';
import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:shepherd_mo/api/api_service.dart';
import 'package:shepherd_mo/models/ceremony.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shepherd_mo/widgets/empty_data.dart';
import 'package:shepherd_mo/widgets/end_of_line.dart';

class CeremonyListDialog extends StatefulWidget {
  const CeremonyListDialog({super.key});

  @override
  _CeremonyListDialogState createState() => _CeremonyListDialogState();
}

class _CeremonyListDialogState extends State<CeremonyListDialog> {
  static const _pageSize = 10;
  final PagingController<int, Ceremony> _pagingController =
      PagingController(firstPageKey: 1, invisibleItemsThreshold: 1);

  String _searchText = ''; // Empty to show all items initially
  Timer? _debounce; // Timer for debouncing
  final searchController = TextEditingController();
  final searchFocus = FocusNode();

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

      final newItems = await apiService.fetchCeremonies(
        searchKey: _searchText,
        pageNumber: pageKey,
        pageSize: _pageSize,
      );

      final isLastPage = newItems.length < _pageSize;

      if (isLastPage) {
        _pagingController.appendLastPage(newItems);
      } else {
        final nextPageKey = pageKey + 1;
        _pagingController.appendPage(newItems, nextPageKey);
      }
    } catch (e) {
      _pagingController.error = e;
    }
  }

  void _unfocus() {
    FocusScope.of(context).unfocus();
  }

  // Method to refresh the entire list
  Future<void> _refreshList() async {
    _searchText = ''; // Reset search text if needed
    _pagingController.refresh(); // Refresh the PagingController
  }

  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _searchText = value;
          _pagingController.refresh(); // Refresh list on new search term
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;
    final localizations = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: _unfocus,
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16.0),
                  topRight: Radius.circular(16.0),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Center(
                  child: Text(
                    localizations.ceremony,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
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
                  SizedBox(height: screenHeight * 0.02),
                  SizedBox(
                    height: screenHeight * 0.3,
                    child: RefreshIndicator(
                      displacement: 20,
                      onRefresh: _refreshList, // Triggers the refresh method
                      child: PagedListView<int, Ceremony>(
                        pagingController: _pagingController,
                        builderDelegate: PagedChildBuilderDelegate<Ceremony>(
                          itemBuilder: (context, item, index) => ListTile(
                            title: Text(item.name ?? localizations.noData),
                            onTap: () => Navigator.of(context).pop(item),
                          ),
                          firstPageProgressIndicatorBuilder: (_) =>
                              const Center(child: CircularProgressIndicator()),
                          newPageProgressIndicatorBuilder: (_) =>
                              const Center(child: CircularProgressIndicator()),
                          noItemsFoundIndicatorBuilder: (context) => _searchText
                                  .isNotEmpty
                              ? EmptyData(
                                  noDataMessage: localizations.noResult,
                                  message: localizations.godAlwaysByYourSide)
                              : EmptyData(
                                  noDataMessage: localizations.noCeremony,
                                  message: localizations.godAlwaysByYourSide),
                          noMoreItemsIndicatorBuilder: (_) => EndOfListWidget(),
                        ),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: Text(localizations.close),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pagingController.dispose();
    searchController.dispose();
    _debounce?.cancel(); // Cancel debounce timer if active
    super.dispose();
  }
}
