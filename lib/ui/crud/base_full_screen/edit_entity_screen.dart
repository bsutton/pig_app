// import 'package:flutter/material.dart';

// import '../../widgets/save_and_close.dart';

// abstract class EntityState<E extends Entity<E>> {
//   Future<E> forInsert();
//   Future<E> forUpdate(E entity);
//   void refresh();
//   E? currentEntity;
// }

// class EntityEditScreen<E extends Entity<E>> extends StatefulWidget {
//   const EntityEditScreen({
//     required this.editor,
//     required this.entityName,
//     required this.entityState,
//     required this.dao,
//     this.scrollController,
//     super.key,
//   });

//   final String entityName;
//   final Dao<E> dao;

//   final Widget Function(E? entity, {required bool isNew}) editor;
//   final EntityState<E> entityState;
//   final ScrollController? scrollController;

//   @override
//   EntityEditScreenState createState() => EntityEditScreenState<E>();
// }

// class EntityEditScreenState<E extends Entity<E>>
//     extends State<EntityEditScreen<E>> {
//   final _formKey = GlobalKey<FormState>();

//   @override
//   Widget build(BuildContext context) => Scaffold(
//         appBar: AppBar(
//           title: Text(widget.entityState.currentEntity != null
//               ? 'Edit ${widget.entityName}'
//               : 'Add ${widget.entityName}'),
//         ),
//         body: Padding(
//           padding: const EdgeInsets.all(4),
//           child: Form(
//             key: _formKey,
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.stretch,
//               children: [
//                 _commandButtons(context),

//                 /// Inject the entity-specific editor.
//                 Expanded(
//                   child: SingleChildScrollView(
//                     key: PageStorageKey(

//                         /// the entity id's are not unique across tables
//                         /// so we use the createdDate which is in reality
//                         /// unique in all realworld scenarios.
//                         widget.entityState.currentEntity?.createdDate),
//                     // controller: widget.scrollController ??
//                     //     ScrollController(), // Attach the controller here
//                     padding: const EdgeInsets.all(4),
//                     child: widget.editor(widget.entityState.currentEntity,
//                         isNew: isNew),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       );

//   /// Display the Save/Cancel Buttons.
//   Widget _commandButtons(BuildContext context) => SaveAndClose(
//       onSave: _save,
//       showSaveOnly: isNew,
//       onCancel: () async {
//         Navigator.of(context).pop();
//       });

//   /// Save the entity
//   Future<void> _save({bool close = false}) async {
//     if (_formKey.currentState!.validate()) {
//       if (widget.entityState.currentEntity != null) {
//         // Update existing entity
//         final updatedEntity = await widget.entityState
//             .forUpdate(widget.entityState.currentEntity!);
//         await widget.dao.update(updatedEntity);
//         setState(() {
//           widget.entityState.currentEntity = updatedEntity;
//         });
//       } else {
//         // Insert new entity
//         final newEntity = await widget.entityState.forInsert();
//         await widget.dao.insert(newEntity);
//         setState(() {
//           widget.entityState.currentEntity = newEntity;
//         });
//       }

//       if (close && mounted) {
//         Navigator.of(context).pop(widget.entityState.currentEntity);
//       } else {
//         setState(() {});
//       }
//     }
//   }

//   bool get isNew => widget.entityState.currentEntity == null;
// }
