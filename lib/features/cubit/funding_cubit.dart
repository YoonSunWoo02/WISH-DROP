import 'package:flutter_bloc/flutter_bloc.dart';
// 👇 경로 수정됨
import 'package:wish_drop/features/data/funding_repository.dart';
import 'package:wish_drop/features/data/project_model.dart';

// --- State ---
abstract class FundingState {}

class FundingInitial extends FundingState {}

class FundingLoading extends FundingState {}

class FundingLoaded extends FundingState {
  final List<ProjectModel> projects;
  FundingLoaded(this.projects);
}

class FundingError extends FundingState {
  final String message;
  FundingError(this.message);
}

// --- Cubit ---
class FundingCubit extends Cubit<FundingState> {
  final FundingRepository _repository;

  FundingCubit(this._repository) : super(FundingInitial()) {
    loadProjects(); // 생성되자마자 데이터 로드 시작
  }

  Future<void> loadProjects() async {
    try {
      emit(FundingLoading());
      final projects = await _repository.fetchProjects();
      emit(FundingLoaded(projects));
    } catch (e) {
      emit(FundingError("데이터 불러오기 실패: $e"));
    }
  }
}
