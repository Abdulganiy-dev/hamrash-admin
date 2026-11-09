import 'package:flutter/material.dart';
import 'package:hamrash_admin/core/widgets/animated_section_content.dart';
import 'package:hamrash_admin/core/widgets/default_scaffold.dart';
import 'package:hamrash_admin/core/widgets/load_error_view.dart';
import 'package:hamrash_admin/views/classes/widgets/classes_skeleton.dart';

/// The body of every Grading page: skeleton while it loads, the error view with
/// a retry, or the content, switched with the blur-and-fade of
/// [AnimatedSectionContent] (a full-page body, so no height morph).
///
/// [stateKey] names the visual state (for example 'empty' then 'columns'); it
/// must change when the state does, which is what drives the cross-transition.
/// Both [stateKey] and [content] are only called once there is something to
/// show, so they can read data that isn't there while loading.
class GradingBody extends StatelessWidget {
  const GradingBody({
    super.key,
    required this.loading,
    required this.error,
    required this.onRetry,
    required this.stateKey,
    required this.content,
  });

  final bool loading;
  final Object? error;
  final VoidCallback onRetry;
  final String Function() stateKey;
  final Widget Function() content;

  @override
  Widget build(BuildContext context) => AnimatedSectionContent(
    morphHeight: false,
    child: error != null
        ? LoadErrorView(key: const ValueKey('error'), onRetry: onRetry)
        : loading
        ? const GradingLoading(key: ValueKey('loading'))
        : KeyedSubtree(key: ValueKey(stateKey()), child: content()),
  );
}

/// [ClassesSkeleton] where the page's content starts.
class GradingLoading extends StatelessWidget {
  const GradingLoading({super.key});

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    physics: const NeverScrollableScrollPhysics(),
    child: Builder(
      builder: (context) => ScaffoldColumn(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: ScaffoldInsets.of(context).bodyTopInset),
          const ClassesSkeleton(),
        ],
      ),
    ),
  );
}
