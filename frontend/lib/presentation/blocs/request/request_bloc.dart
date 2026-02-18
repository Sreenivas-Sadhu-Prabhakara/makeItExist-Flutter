import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/network/api_exceptions.dart';
import '../../../data/models/request_model.dart';
import '../../../data/repositories/request_repository.dart';
import 'request_event.dart';
import 'request_state.dart';

class RequestBloc extends Bloc<RequestEvent, RequestState> {
  final RequestRepository requestRepository;

  RequestBloc({required this.requestRepository}) : super(RequestInitial()) {
    on<LoadRequests>(_onLoadRequests);
    on<CreateRequest>(_onCreateRequest);
    on<LoadRequestDetail>(_onLoadRequestDetail);
  }

  Future<void> _onLoadRequests(LoadRequests event, Emitter<RequestState> emit) async {
    emit(RequestLoading());
    try {
      final requests = await requestRepository.getMyRequests();
      emit(RequestsLoaded(requests: requests));
    } on ApiException catch (e) {
      emit(RequestError(message: e.message));
    } catch (e) {
      emit(RequestError(message: 'Failed to load requests'));
    }
  }

  Future<void> _onCreateRequest(CreateRequest event, Emitter<RequestState> emit) async {
    emit(RequestSubmitting());
    try {
      final request = await requestRepository.createRequest(event.input);
      emit(RequestCreated(request: request));
    } on ApiException catch (e) {
      emit(RequestError(message: e.message));
    } catch (e) {
      emit(RequestError(message: 'Failed to submit request'));
    }
  }

  Future<void> _onLoadRequestDetail(LoadRequestDetail event, Emitter<RequestState> emit) async {
    emit(RequestLoading());
    try {
      final request = await requestRepository.getRequestById(event.id);
      emit(RequestDetailLoaded(request: request));
    } on ApiException catch (e) {
      emit(RequestError(message: e.message));
    } catch (e) {
      emit(RequestError(message: 'Failed to load request details'));
    }
  }
}
