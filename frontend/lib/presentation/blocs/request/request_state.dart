import '../../../data/models/request_model.dart';

abstract class RequestState {}

class RequestInitial extends RequestState {}

class RequestLoading extends RequestState {}

class RequestSubmitting extends RequestState {}

class RequestsLoaded extends RequestState {
  final List<BuildRequestModel> requests;
  RequestsLoaded({required this.requests});
}

class RequestCreated extends RequestState {
  final BuildRequestModel request;
  RequestCreated({required this.request});
}

class RequestDetailLoaded extends RequestState {
  final BuildRequestModel request;
  RequestDetailLoaded({required this.request});
}

class RequestError extends RequestState {
  final String message;
  RequestError({required this.message});
}
