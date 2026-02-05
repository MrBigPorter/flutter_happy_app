// define a step in the pipeline, which is a unit of work that can be executed in the pipeline.
abstract class PipelineStep<T> {
  // Each step must implement the execute method, which takes a context of type T and performs the necessary work.
  Future<void> execute(T ctx);
}