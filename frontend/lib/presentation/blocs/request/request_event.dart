import '../../../data/models/request_model.dart';

abstract class RequestEvent {}

class LoadRequests extends RequestEvent {}

class CreateRequest extends RequestEvent {
  final CreateBuildRequestInput input;
  CreateRequest({required this.input});
}

class LoadRequestDetail extends RequestEvent {
  final String id;
  LoadRequestDetail({required this.id});
}
