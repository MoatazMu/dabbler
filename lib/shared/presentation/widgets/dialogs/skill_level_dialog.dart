/// Interactive skill level selection dialog
library;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Skill level data for selection
class SkillLevelOption {
  final int level;
  final String name;
  final String shortDescription;
  final String detailedDescription;
  final List<String> characteristics;
  final List<String> examples;
  final String comparisonText;
  final Color color;
  final IconData icon;
  
  const SkillLevelOption({
    required this.level,
    required this.name,
    required this.shortDescription,
    required this.detailedDescription,
    required this.characteristics,
    required this.examples,
    required this.comparisonText,
    required this.color,
    required this.icon,
  });
}

/// Sport data for skill assessment
class SportSkillData {
  final String id;
  final String name;
  final String category;
  final IconData icon;
  final Color color;
  final List<SkillLevelOption> levels;
  final List<AssessmentQuestion> questions;
  final int? selectedLevel;
  final bool isCompleted;
  
  const SportSkillData({
    required this.id,
    required this.name,
    required this.category,
    required this.icon,
    required this.color,
    required this.levels,
    required this.questions,
    this.selectedLevel,
    this.isCompleted = false,
  });
  
  SportSkillData copyWith({
    String? id,
    String? name,
    String? category,
    IconData? icon,
    Color? color,
    List<SkillLevelOption>? levels,
    List<AssessmentQuestion>? questions,
    int? selectedLevel,
    bool? isCompleted,
  }) {
    return SportSkillData(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      levels: levels ?? this.levels,
      questions: questions ?? this.questions,
      selectedLevel: selectedLevel ?? this.selectedLevel,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
  
  SkillLevelOption? get selectedLevelOption => 
      selectedLevel != null ? levels.firstWhere((l) => l.level == selectedLevel) : null;
}

/// Assessment question for skill evaluation
class AssessmentQuestion {
  final String id;
  final String question;
  final List<AssessmentAnswer> answers;
  final String? explanation;
  final int? selectedAnswerId;
  
  const AssessmentQuestion({
    required this.id,
    required this.question,
    required this.answers,
    this.explanation,
    this.selectedAnswerId,
  });
  
  AssessmentQuestion copyWith({
    String? id,
    String? question,
    List<AssessmentAnswer>? answers,
    String? explanation,
    int? selectedAnswerId,
  }) {
    return AssessmentQuestion(
      id: id ?? this.id,
      question: question ?? this.question,
      answers: answers ?? this.answers,
      explanation: explanation ?? this.explanation,
      selectedAnswerId: selectedAnswerId ?? this.selectedAnswerId,
    );
  }
  
  bool get isAnswered => selectedAnswerId != null;
  
  AssessmentAnswer? get selectedAnswer => 
      selectedAnswerId != null ? answers.firstWhere((a) => a.id == selectedAnswerId) : null;
}

/// Assessment answer option
class AssessmentAnswer {
  final int id;
  final String text;
  final int skillLevelWeight;
  final String? explanation;
  
  const AssessmentAnswer({
    required this.id,
    required this.text,
    required this.skillLevelWeight,
    this.explanation,
  });
}

/// Skill level selection dialog
class SkillLevelDialog extends StatefulWidget {
  final List<SportSkillData> sports;
  final bool enableAssessment;
  final bool enableComparison;
  final bool showProgress;
  final Function(List<SportSkillData>)? onSportsUpdated;
  final Function(SportSkillData, int)? onSkillLevelSelected;
  final VoidCallback? onCompleted;
  final VoidCallback? onSkipped;
  final VoidCallback? onClose;
  final Duration animationDuration;
  final bool enableHapticFeedback;
  final String title;
  final String subtitle;
  
  const SkillLevelDialog({
    super.key,
    required this.sports,
    this.enableAssessment = true,
    this.enableComparison = true,
    this.showProgress = true,
    this.onSportsUpdated,
    this.onSkillLevelSelected,
    this.onCompleted,
    this.onSkipped,
    this.onClose,
    this.animationDuration = const Duration(milliseconds: 300),
    this.enableHapticFeedback = true,
    this.title = 'Set Your Skill Levels',
    this.subtitle = 'Help us match you with the right players',
  });
  
  static Future<T?> show<T>({
    required BuildContext context,
    required List<SportSkillData> sports,
    bool enableAssessment = true,
    bool enableComparison = true,
    bool showProgress = true,
    Function(List<SportSkillData>)? onSportsUpdated,
    Function(SportSkillData, int)? onSkillLevelSelected,
    VoidCallback? onCompleted,
    VoidCallback? onSkipped,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: false,
      builder: (context) => SkillLevelDialog(
        sports: sports,
        enableAssessment: enableAssessment,
        enableComparison: enableComparison,
        showProgress: showProgress,
        onSportsUpdated: onSportsUpdated,
        onSkillLevelSelected: onSkillLevelSelected,
        onCompleted: onCompleted,
        onSkipped: onSkipped,
        onClose: () => Navigator.of(context).pop(),
      ),
    );
  }
  
  @override
  State<SkillLevelDialog> createState() => _SkillLevelDialogState();
}

class _SkillLevelDialogState extends State<SkillLevelDialog>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _slideController;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;
  
  final PageController _pageController = PageController();
  
  List<SportSkillData> _sports = [];
  int _currentSportIndex = 0;
  bool _showAssessment = false;
  int _currentQuestionIndex = 0;
  
  @override
  void initState() {
    super.initState();
    _sports = List.from(widget.sports);
    _setupAnimations();
    _startEntranceAnimation();
  }
  
  void _setupAnimations() {
    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
  }
  
  void _startEntranceAnimation() {
    _animationController.forward();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    _slideController.dispose();
    _pageController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Dialog.fullscreen(
            child: Scaffold(
              backgroundColor: Colors.white,
              body: _buildDialogContent(),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildDialogContent() {
    return Column(
      children: [
        // Header
        _buildHeader(),
        
        // Progress indicator
        if (widget.showProgress && _sports.length > 1)
          _buildProgressIndicator(),
        
        // Content
        Expanded(
          child: _showAssessment 
              ? _buildAssessmentContent()
              : _buildSkillSelectionContent(),
        ),
        
        // Footer
        _buildFooter(),
      ],
    );
  }
  
  Widget _buildHeader() {
    final currentSport = _currentSportIndex < _sports.length 
        ? _sports[_currentSportIndex] 
        : null;
    
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 16,
        right: 16,
        bottom: 16,
      ),
      decoration: BoxDecoration(
        color: currentSport?.color ?? Theme.of(context).primaryColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: _handleBack,
                icon: const Icon(
                  Icons.close,
                  color: Colors.white,
                ),
              ),
              
              Expanded(
                child: Text(
                  _showAssessment ? 'Skill Assessment' : widget.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              
              if (!_showAssessment)
                TextButton(
                  onPressed: _handleSkip,
                  child: const Text(
                    'Skip',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
            ],
          ),
          
          if (currentSport != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  currentSport.icon,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 8),
                
                Text(
                  currentSport.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 4),
            Text(
              _showAssessment 
                  ? 'Answer questions to determine your skill level'
                  : widget.subtitle,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildProgressIndicator() {
    final progress = (_currentSportIndex + 1) / _sports.length;
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Sport ${_currentSportIndex + 1} of ${_sports.length}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
              
              Text(
                '${(progress * 100).round()}% Complete',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                _currentSportIndex < _sports.length 
                    ? _sports[_currentSportIndex].color
                    : Theme.of(context).primaryColor,
              ),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSkillSelectionContent() {
    if (_currentSportIndex >= _sports.length) {
      return _buildCompletionContent();
    }
    
    final currentSport = _sports[_currentSportIndex];
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sport description
          _buildSportDescription(currentSport),
          
          const SizedBox(height: 24),
          
          // Skill level options
          _buildSkillLevelOptions(currentSport),
          
          if (widget.enableAssessment && currentSport.questions.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildAssessmentOption(),
          ],
        ],
      ),
    );
  }
  
  Widget _buildSportDescription(SportSkillData sport) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: sport.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: sport.color.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: sport.color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  sport.icon,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sport.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    
                    Text(
                      sport.category,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          Text(
            'Select your current skill level to help us match you with suitable players and activities.',
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSkillLevelOptions(SportSkillData sport) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Choose Your Skill Level',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        
        const SizedBox(height: 16),
        
        ...sport.levels.map((level) {
          return _buildSkillLevelCard(sport, level);
        }),
      ],
    );
  }
  
  Widget _buildSkillLevelCard(SportSkillData sport, SkillLevelOption level) {
    final isSelected = sport.selectedLevel == level.level;
    
    return GestureDetector(
      onTap: () => _selectSkillLevel(sport, level.level),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected 
              ? sport.color.withOpacity(0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
                ? sport.color 
                : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: sport.color.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? sport.color 
                        : Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    level.icon,
                    color: isSelected ? Colors.white : Colors.grey[600],
                    size: 20,
                  ),
                ),
                
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Level ${level.level}',
                            style: TextStyle(
                              fontSize: 12,
                              color: isSelected 
                                  ? sport.color 
                                  : Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              level.name,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: isSelected 
                                    ? sport.color 
                                    : Colors.grey[800],
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 4),
                      Text(
                        level.shortDescription,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    color: sport.color,
                    size: 24,
                  ),
              ],
            ),
            
            if (isSelected) ...[
              const SizedBox(height: 12),
              _buildLevelDetails(level),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildLevelDetails(SkillLevelOption level) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            level.detailedDescription,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          
          if (level.characteristics.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'Characteristics:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            
            ...level.characteristics.map((characteristic) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '• ',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        characteristic,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
          
          if (level.examples.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'Examples:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            
            ...level.examples.map((example) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '• ',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        example,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
          
          if (level.comparisonText.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.people,
                    size: 16,
                    color: Colors.blue[600],
                  ),
                  const SizedBox(width: 8),
                  
                  Expanded(
                    child: Text(
                      level.comparisonText,
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildAssessmentOption() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.quiz,
                color: Colors.orange[600],
                size: 24,
              ),
              const SizedBox(width: 12),
              
              const Expanded(
                child: Text(
                  'Not sure about your level?',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          Text(
            'Take our quick assessment to help determine your skill level based on your experience and abilities.',
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 14,
            ),
          ),
          
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _startAssessment,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[600],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Take Assessment',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildAssessmentContent() {
    if (_currentSportIndex >= _sports.length) return const SizedBox.shrink();
    
    final currentSport = _sports[_currentSportIndex];
    final questions = currentSport.questions;
    
    if (_currentQuestionIndex >= questions.length) {
      return _buildAssessmentResults(currentSport);
    }
    
    final currentQuestion = questions[_currentQuestionIndex];
    
    return AnimatedBuilder(
      animation: _slideController,
      builder: (context, child) {
        return SlideTransition(
          position: _slideAnimation,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Question progress
                _buildQuestionProgress(questions),
                
                const SizedBox(height: 24),
                
                // Question
                _buildQuestionCard(currentQuestion),
                
                const SizedBox(height: 24),
                
                // Answer options
                _buildAnswerOptions(currentQuestion),
                
                if (currentQuestion.explanation != null && currentQuestion.isAnswered) ...[
                  const SizedBox(height: 16),
                  _buildQuestionExplanation(currentQuestion.explanation!),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildQuestionProgress(List<AssessmentQuestion> questions) {
    final progress = (_currentQuestionIndex + 1) / questions.length;
    
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Question ${_currentQuestionIndex + 1} of ${questions.length}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            
            Text(
              '${(progress * 100).round()}%',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(
              _sports[_currentSportIndex].color,
            ),
            minHeight: 4,
          ),
        ),
      ],
    );
  }
  
  Widget _buildQuestionCard(AssessmentQuestion question) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        question.question,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          height: 1.4,
        ),
      ),
    );
  }
  
  Widget _buildAnswerOptions(AssessmentQuestion question) {
    return Column(
      children: question.answers.map((answer) {
        return _buildAnswerOption(question, answer);
      }).toList(),
    );
  }
  
  Widget _buildAnswerOption(AssessmentQuestion question, AssessmentAnswer answer) {
    final isSelected = question.selectedAnswerId == answer.id;
    final sport = _sports[_currentSportIndex];
    
    return GestureDetector(
      onTap: () => _selectAnswer(question, answer),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected 
              ? sport.color.withOpacity(0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
                ? sport.color 
                : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected 
                      ? sport.color 
                      : Colors.grey[400]!,
                  width: 2,
                ),
                color: isSelected 
                    ? sport.color 
                    : Colors.transparent,
              ),
              child: isSelected 
                  ? const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 16,
                    )
                  : null,
            ),
            
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                answer.text,
                style: TextStyle(
                  fontSize: 16,
                  color: isSelected 
                      ? sport.color 
                      : Colors.grey[800],
                  fontWeight: isSelected 
                      ? FontWeight.w500 
                      : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildQuestionExplanation(String explanation) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info,
            color: Colors.blue[600],
            size: 20,
          ),
          const SizedBox(width: 8),
          
          Expanded(
            child: Text(
              explanation,
              style: TextStyle(
                color: Colors.blue[700],
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildAssessmentResults(SportSkillData sport) {
    final suggestedLevel = _calculateSuggestedLevel(sport);
    final suggestedLevelOption = sport.levels.firstWhere(
      (level) => level.level == suggestedLevel,
    );
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: sport.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: sport.color.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: sport.color,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    suggestedLevelOption.icon,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                
                const SizedBox(height: 16),
                const Text(
                  'Assessment Complete!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                
                const SizedBox(height: 8),
                Text(
                  'Based on your answers, we suggest:',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                
                const SizedBox(height: 16),
                Text(
                  'Level $suggestedLevel - ${suggestedLevelOption.name}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: sport.color,
                  ),
                ),
                
                const SizedBox(height: 8),
                Text(
                  suggestedLevelOption.shortDescription,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _selectSkillLevel(sport, suggestedLevel),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: sport.color),
                  ),
                  child: Text(
                    'Accept Suggestion',
                    style: TextStyle(
                      color: sport.color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _exitAssessment,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: sport.color,
                  ),
                  child: const Text(
                    'Choose Manually',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildCompletionContent() {
    final completedSports = _sports.where((sport) => sport.selectedLevel != null).length;
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: const Icon(
              Icons.check,
              color: Colors.white,
              size: 50,
            ),
          ),
          
          const SizedBox(height: 24),
          const Text(
            'Skill Levels Set!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
          ),
          
          const SizedBox(height: 8),
          Text(
            'You\'ve set skill levels for $completedSports sport${completedSports == 1 ? '' : 's'}.',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 32),
          _buildSkillSummary(),
        ],
      ),
    );
  }
  
  Widget _buildSkillSummary() {
    final completedSports = _sports.where((sport) => sport.selectedLevel != null);
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Skill Levels:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          
          const SizedBox(height: 12),
          ...completedSports.map((sport) {
            final levelOption = sport.selectedLevelOption!;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: sport.color,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      sport.icon,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      sport.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  
                  Text(
                    'Level ${levelOption.level} - ${levelOption.name}',
                    style: TextStyle(
                      color: sport.color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
  
  Widget _buildFooter() {
    if (_showAssessment) {
      return _buildAssessmentFooter();
    }
    
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Row(
        children: [
          if (_currentSportIndex > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _previousSport,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Previous'),
              ),
            ),
          
          if (_currentSportIndex > 0)
            const SizedBox(width: 16),
          
          Expanded(
            child: ElevatedButton(
              onPressed: _canContinue() ? _nextSport : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                _currentSportIndex >= _sports.length - 1
                    ? 'Complete'
                    : 'Continue',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildAssessmentFooter() {
    final currentSport = _sports[_currentSportIndex];
    final questions = currentSport.questions;
    final currentQuestion = _currentQuestionIndex < questions.length
        ? questions[_currentQuestionIndex]
        : null;
    
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Row(
        children: [
          if (_currentQuestionIndex > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _previousQuestion,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Previous'),
              ),
            ),
          
          if (_currentQuestionIndex > 0)
            const SizedBox(width: 16),
          
          Expanded(
            child: ElevatedButton(
              onPressed: currentQuestion?.isAnswered == true 
                  ? _nextQuestion 
                  : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                _currentQuestionIndex >= questions.length - 1
                    ? 'Finish Assessment'
                    : 'Next Question',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  bool _canContinue() {
    if (_currentSportIndex >= _sports.length) return true;
    
    final currentSport = _sports[_currentSportIndex];
    return currentSport.selectedLevel != null;
  }
  
  void _handleBack() {
    if (widget.enableHapticFeedback) {
      HapticFeedback.selectionClick();
    }
    
    if (_showAssessment) {
      _exitAssessment();
    } else {
      widget.onClose?.call();
    }
  }
  
  void _handleSkip() {
    if (widget.enableHapticFeedback) {
      HapticFeedback.selectionClick();
    }
    
    widget.onSkipped?.call();
    widget.onClose?.call();
  }
  
  void _selectSkillLevel(SportSkillData sport, int level) {
    if (widget.enableHapticFeedback) {
      HapticFeedback.selectionClick();
    }
    
    final updatedSport = sport.copyWith(selectedLevel: level);
    final sportIndex = _sports.indexWhere((s) => s.id == sport.id);
    
    setState(() {
      _sports[sportIndex] = updatedSport;
    });
    
    widget.onSkillLevelSelected?.call(updatedSport, level);
    widget.onSportsUpdated?.call(_sports);
  }
  
  void _nextSport() {
    if (widget.enableHapticFeedback) {
      HapticFeedback.selectionClick();
    }
    
    if (_currentSportIndex >= _sports.length - 1) {
      widget.onCompleted?.call();
      widget.onClose?.call();
    } else {
      setState(() {
        _currentSportIndex++;
      });
      
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }
  
  void _previousSport() {
    if (widget.enableHapticFeedback) {
      HapticFeedback.selectionClick();
    }
    
    if (_currentSportIndex > 0) {
      setState(() {
        _currentSportIndex--;
      });
      
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }
  
  void _startAssessment() {
    if (widget.enableHapticFeedback) {
      HapticFeedback.selectionClick();
    }
    
    setState(() {
      _showAssessment = true;
      _currentQuestionIndex = 0;
    });
    
    _slideController.forward();
  }
  
  void _exitAssessment() {
    if (widget.enableHapticFeedback) {
      HapticFeedback.selectionClick();
    }
    
    _slideController.reverse().then((_) {
      setState(() {
        _showAssessment = false;
        _currentQuestionIndex = 0;
      });
    });
  }
  
  void _selectAnswer(AssessmentQuestion question, AssessmentAnswer answer) {
    if (widget.enableHapticFeedback) {
      HapticFeedback.selectionClick();
    }
    
    final updatedQuestion = question.copyWith(selectedAnswerId: answer.id);
    final sport = _sports[_currentSportIndex];
    final questionIndex = sport.questions.indexWhere((q) => q.id == question.id);
    
    final updatedQuestions = List<AssessmentQuestion>.from(sport.questions);
    updatedQuestions[questionIndex] = updatedQuestion;
    
    final updatedSport = sport.copyWith(questions: updatedQuestions);
    
    setState(() {
      _sports[_currentSportIndex] = updatedSport;
    });
    
    // Auto-advance after a short delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _nextQuestion();
      }
    });
  }
  
  void _nextQuestion() {
    if (widget.enableHapticFeedback) {
      HapticFeedback.selectionClick();
    }
    
    final sport = _sports[_currentSportIndex];
    
    if (_currentQuestionIndex < sport.questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
      
      _slideController.reset();
      _slideController.forward();
    } else {
      // Assessment complete, show results
      setState(() {
        _currentQuestionIndex++;
      });
    }
  }
  
  void _previousQuestion() {
    if (widget.enableHapticFeedback) {
      HapticFeedback.selectionClick();
    }
    
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
      });
      
      _slideController.reset();
      _slideController.forward();
    }
  }
  
  int _calculateSuggestedLevel(SportSkillData sport) {
    final answeredQuestions = sport.questions.where((q) => q.isAnswered);
    
    if (answeredQuestions.isEmpty) return 1;
    
    final totalWeight = answeredQuestions.fold<int>(0, (sum, question) {
      return sum + question.selectedAnswer!.skillLevelWeight;
    });
    
    final averageWeight = totalWeight / answeredQuestions.length;
    
    // Convert average weight to skill level (1-10)
    return (averageWeight.clamp(1, 10)).round();
  }
}

/// Predefined skill level options
class SkillLevelPresets {
  /// Tennis skill levels
  static List<SkillLevelOption> tennisLevels = [
    const SkillLevelOption(
      level: 1,
      name: 'Beginner',
      shortDescription: 'Just starting out',
      detailedDescription: 'New to tennis, learning basic strokes and rules.',
      characteristics: [
        'Learning basic forehand and backhand',
        'Understanding court dimensions and scoring',
        'Working on consistency and ball control',
      ],
      examples: [
        'First time playing tennis',
        'Taking beginner lessons',
        'Can hit some balls over the net',
      ],
      comparisonText: 'Similar to recreational players just starting',
      color: Colors.green,
      icon: Icons.sports_tennis,
    ),
    const SkillLevelOption(
      level: 5,
      name: 'Intermediate',
      shortDescription: 'Comfortable player',
      detailedDescription: 'Can play consistent rallies and knows basic strategy.',
      characteristics: [
        'Consistent groundstrokes',
        'Basic serve and return',
        'Understanding of court positioning',
      ],
      examples: [
        'Playing in local leagues',
        'Can sustain rallies',
        'Has favorite shots and strategies',
      ],
      comparisonText: 'Similar to club-level recreational players',
      color: Colors.orange,
      icon: Icons.sports_tennis,
    ),
    const SkillLevelOption(
      level: 9,
      name: 'Advanced',
      shortDescription: 'Competitive player',
      detailedDescription: 'Strong technical skills and tactical awareness.',
      characteristics: [
        'All strokes including advanced shots',
        'Strategic play and court coverage',
        'Mental toughness in competition',
      ],
      examples: [
        'Tournament play',
        'Teaching or coaching others',
        'Consistent winners and shot placement',
      ],
      comparisonText: 'Similar to tournament and competitive players',
      color: Colors.red,
      icon: Icons.sports_tennis,
    ),
  ];
  
  /// Sample assessment questions for tennis
  static List<AssessmentQuestion> tennisQuestions = [
    const AssessmentQuestion(
      id: '1',
      question: 'How would you describe your serving ability?',
      answers: [
        AssessmentAnswer(
          id: 1,
          text: 'I\'m still learning the basic serving motion',
          skillLevelWeight: 2,
        ),
        AssessmentAnswer(
          id: 2,
          text: 'I can serve consistently but not with much power',
          skillLevelWeight: 4,
        ),
        AssessmentAnswer(
          id: 3,
          text: 'I have a reliable serve with good placement',
          skillLevelWeight: 6,
        ),
        AssessmentAnswer(
          id: 4,
          text: 'I have multiple serve types and can place them strategically',
          skillLevelWeight: 8,
        ),
      ],
      explanation: 'Your serving ability is a good indicator of overall tennis skill level.',
    ),
    const AssessmentQuestion(
      id: '2',
      question: 'How long can you typically sustain a rally?',
      answers: [
        AssessmentAnswer(
          id: 1,
          text: 'I usually hit it into the net or out after 1-3 shots',
          skillLevelWeight: 1,
        ),
        AssessmentAnswer(
          id: 2,
          text: 'I can keep the ball going for 4-8 shots',
          skillLevelWeight: 3,
        ),
        AssessmentAnswer(
          id: 3,
          text: 'I can sustain rallies for 10+ shots consistently',
          skillLevelWeight: 6,
        ),
        AssessmentAnswer(
          id: 4,
          text: 'I can play long rallies and control the pace',
          skillLevelWeight: 8,
        ),
      ],
    ),
  ];
  
  /// Sample sports with skill levels
  static List<SportSkillData> sampleSports = [
    SportSkillData(
      id: 'tennis',
      name: 'Tennis',
      category: 'Racket Sports',
      icon: Icons.sports_tennis,
      color: Colors.green,
      levels: tennisLevels,
      questions: tennisQuestions,
    ),
    SportSkillData(
      id: 'basketball',
      name: 'Basketball',
      category: 'Ball Sports',
      icon: Icons.sports_basketball,
      color: Colors.orange,
      levels: [
        const SkillLevelOption(
          level: 1,
          name: 'Beginner',
          shortDescription: 'Learning the basics',
          detailedDescription: 'New to basketball, learning to dribble and shoot.',
          characteristics: ['Basic dribbling', 'Learning to shoot', 'Understanding rules'],
          examples: ['First time playing', 'Recreational games'],
          comparisonText: 'Similar to pickup game beginners',
          color: Colors.blue,
          icon: Icons.sports_basketball,
        ),
      ],
      questions: [],
    ),
  ];
}
