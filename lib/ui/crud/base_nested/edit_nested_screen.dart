// import 'package:flutter/material.dart';

// import '../../../dao/dao.dart';
// import '../../../entity/entity.dart';
// import '../../widgets/save_and_close.dart';

// abstract class NestedEntityState<E extends Entity<E>> {
//   Future<E> forInsert();
//   Future<E> forUpdate(E entity);
//   void refresh();
//   E? currentEntity;
// }

// class NestedEntityEditScreen<C extends Entity<C>, P extends Entity<P>>
//     extends StatefulWidget {
//   const NestedEntityEditScreen({
//     required this.editor,
//     required this.onInsert,
//     required this.entityName,
//     required this.entityState,
//     required this.dao,
//     super.key,
//   });

//   final String entityName;
//   final Dao<C> dao;
//   final Widget Function(C? entity) editor;
//   final NestedEntityState<C> entityState;
//   final Future<void> Function(C? entity) onInsert;

//   @override
//   NestedEntityEditScreenState createState() =>
//       NestedEntityEditScreenState<C, P>();
// }

// class NestedEntityEditScreenState<C extends Entity<C>, P extends Entity<P>>
//     extends State<NestedEntityEditScreen<C, P>> {
//   final _formKey = GlobalKey<FormState>();

//   @override
//   void initState() {
//     super.initState();
//   }

//   @override
//   Widget build(BuildContext context) => Scaffold(
//         appBar: AppBar(
//             title: Text(widget.entityState.currentEntity != null
//                 ? 'Edit ${widget.entityName}'
//                 : 'Add ${widget.entityName}'),
//             automaticallyImplyLeading: false),
//         body: Column(
//           children: [
//             _commandButtons(context),
//             Flexible(
//               child: Form(
//                 key: _formKey,
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   crossAxisAlignment: CrossAxisAlignment.stretch,
//                   children: [
//                     Expanded(
//                       child: SingleChildScrollView(
//                         padding: const EdgeInsets.all(4),

//                         /// Inject the entity specific editor.
//                         child: widget.editor(widget.entityState.currentEntity),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       );

//   Widget _commandButtons(BuildContext context) => SaveAndClose(
//       onSave: _save,
//       showSaveOnly: widget.entityState.currentEntity == null,
//       onCancel: () async {
//         Navigator.of(context).pop();
//       });

//   Future<void> _save({bool close = false}) async {
//     if (_formKey.currentState!.validate()) {
//       if (widget.entityState.currentEntity != null) {
//         final updatedEntity = await widget.entityState
//             .forUpdate(widget.entityState.currentEntity as C);
//         await widget.dao.update(updatedEntity);
//         setState(() {
//           widget.entityState.currentEntity = updatedEntity;
//         });
//       } else {
//         final newEntity = await widget.entityState.forInsert();
//         await widget.onInsert(newEntity);
//         widget.entityState.currentEntity = newEntity;
//       }

//       if (close && mounted) {
//         widget.entityState.refresh();
//         Navigator.of(context).pop(widget.entityState.currentEntity);
//       } else {
//         setState(() {});
//       }
//     }
//   }
// }
