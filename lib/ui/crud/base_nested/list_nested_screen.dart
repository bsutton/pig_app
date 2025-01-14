// import 'dart:async';

// import 'package:flutter/material.dart';
// import 'package:future_builder_ex/future_builder_ex.dart';
// import 'package:june/june.dart';

// import '../../../dao/dao.dart';
// import '../../../entity/entities.dart';
// import '../../dialog/hmb_are_you_sure_dialog.dart';
// import '../../widgets/hmb_add_button.dart';
// import '../../widgets/hmb_toast.dart';
// import '../../widgets/hmb_toggle.dart';
// import '../../widgets/layout/hmb_list_card.dart';

// class Parent<P extends Entity<P>> {
//   Parent(this.parent);

//   P? parent;
// }

// enum CardDetail { full, summary }

// typedef Allowed<C> = bool Function(C entity);

// class NestedEntityListScreen<C extends Entity<C>, P extends Entity<P>>
//     extends StatefulWidget {
//   const NestedEntityListScreen({
//     required this.dao,
//     required this.onEdit,
//     required this.onDelete,
//     required this.onInsert,
//     required this.entityNamePlural,
//     required this.title,
//     required this.details,
//     required this.parentTitle,
//     required this.entityNameSingular,
//     required this.parent,
//     required this.fetchList,
//     this.filterBar,
//     this.canEdit,
//     this.canDelete,
//     this.extended = false,
//     super.key,
//   });

//   final Parent<P> parent;
//   final String entityNamePlural;
//   final Widget Function(C entity) title;
//   final Widget Function(P entity)? filterBar;
//   final Widget Function(C entity, CardDetail cardDetail) details;
//   final Widget Function(C? entity) onEdit;
//   final Allowed<C>? canEdit;
//   final Allowed<C>? canDelete;
//   final Future<void> Function(C? entity) onDelete;
//   final Future<void> Function(C? entity) onInsert;
//   final Future<List<C>> Function() fetchList;
//   final Dao<C> dao;
//   final String parentTitle;
//   final String entityNameSingular;

//   /// All cards are displayed on screen rather than in a listview.
//   final bool extended;

//   @override
//   NestedEntityListScreenState createState() =>
//       NestedEntityListScreenState<C, P>();
// }

// class NestedEntityListScreenState<C extends Entity<C>, P extends Entity<P>>
//     extends State<NestedEntityListScreen<C, P>> {
//   late Future<List<C>> entities;

//   CardDetail cardDetail = CardDetail.summary;

//   @override
//   void initState() {
//     super.initState();
//     // entities = _fetchList();
//   }

//   Future<void> _refreshEntityList() async {
//     if (mounted) {
//       setState(() {
//         entities = _fetchList();
//       });
//     }
//   }

//   Future<List<C>> _fetchList() async {
//     if (widget.parent.parent == null) {
//       return <C>[];
//     } else {
//       return widget.fetchList();
//     }
//   }

//   @override
//   Widget build(BuildContext context) => Column(
//         children: [
//           _buildTitle(),
//           _buildBody(),
//         ],
//       );

//   Widget _buildAddButton(BuildContext context) => HMBButtonAdd(
//         enabled: widget.parent.parent != null,
//         onPressed: () async {
//           if (context.mounted) {
//             await Navigator.push(
//               context,
//               MaterialPageRoute<void>(
//                   builder: (context) => widget.onEdit(null)),
//             ).then((_) => _refreshEntityList());
//           }
//         },
//       );

//   Column _buildTitle() => Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Row(children: [
//             Text(
//               widget.entityNamePlural,
//               style: const TextStyle(fontSize: 18),
//             ),
//             const Spacer(),
//             _buildFilter(),
//             _buildAddButton(context),
//           ]),
//         ],
//       );

//   Widget _buildFilter() => Column(
//         mainAxisAlignment: MainAxisAlignment.end,
//         crossAxisAlignment: CrossAxisAlignment.end,
//         children: [
//           HMBToggle(
//             label: 'Show details',
//             tooltip: 'Show/Hide full card details',
//             initialValue: cardDetail == CardDetail.full,
//             onChanged: (on) {
//               setState(() {
//                 cardDetail = on ? CardDetail.full : CardDetail.summary;
//               });
//             },
//           ),
//           if (widget.filterBar != null && widget.parent.parent != null)
//             widget.filterBar!(widget.parent.parent as P),
//         ],
//       );

//   JuneBuilder<JuneState> _buildBody() =>
//       JuneBuilder(widget.dao.juneRefresher, builder: (context) {
//         // return const HMBSpacer(height: true);
//         // ignore: discarded_futures
//         entities = _fetchList();
//         return FutureBuilderEx<List<C>>(
//           future: entities,
//           waitingBuilder: (_) =>
//               const Center(child: CircularProgressIndicator()),
//           builder: (context, list) {
//             if (widget.parent.parent == null) {
//               return Center(
//                   child: Text(
//                 'Save the ${widget.parentTitle} first.',
//                 style:
//                     const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
//               ));
//             }
//             if (list!.isEmpty) {
//               return Center(
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     const Text('Click'),
//                     HMBButtonAdd(
//                         enabled: true,
//                         onPressed: () async {
//                           HMBToast.info('Not this one, the one to the right');
//                         }),
//                     Text('to add a ${widget.entityNameSingular}.'),
//                   ],
//                 ),
//               );
//             } else {
//               return _displayColumn(list, context);
//             }
//           },
//         );
//       });

//   Widget _displayColumn(List<C> list, BuildContext context) {
//     final cards = <Widget>[];

//     for (final entity in list) {
//       cards.add(SizedBox(height: 212, child: _buildCard(entity, context)));
//     }

//     return Column(
//       mainAxisSize: MainAxisSize.min,
//       children: cards,
//     );
//   }

//   Widget _buildCard(C entity, BuildContext context) => HMBCrudListCard(
//       title: widget.title(entity),
//       onDelete: () async => _confirmDelete(entity),
//       onEdit: () => widget.onEdit(entity),
//       canEdit:
//           widget.canEdit == null ? () => true : () => widget.canEdit!(entity),
//       canDelete: widget.canDelete == null
//           ? () => true
//           : () => widget.canDelete!(entity),
//       onRefresh: _refreshEntityList,
//       child: Padding(
//         padding: const EdgeInsets.only(left: 8),
//         child: widget.details(entity, cardDetail),
//       ));

//   Future<void> _confirmDelete(C entity) async {
//     await areYouSure(
//         context: context,
//         title: 'Delete Confirmation',
//         message: 'Are you sure you want to delete this item?',
//         onConfirmed: () async => _delete(entity));
//   }

//   Future<void> _delete(C entity) async {
//     await widget.onDelete(entity);
//     await _refreshEntityList();
//   }
// }
