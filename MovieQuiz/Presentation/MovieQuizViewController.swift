import UIKit

final class MovieQuizViewController: UIViewController, QuestionFactoryDelegate {
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    @IBOutlet private weak var noButton: UIButton!
    
    @IBOutlet private weak var yesButton: UIButton!
    
    @IBOutlet private weak var imageView: UIImageView!
    
    @IBOutlet private weak var textLabel: UILabel!
    
    @IBOutlet private weak var counterLabel: UILabel!
    
    private var currentQuestionIndex = 0
    
    private var correctAnswers = 0
    
    private let questionsAmount: Int = 10
    
    private var questionFactory: QuestionFactoryProtocol?
    
    private var currentQuestion: QuizQuestion?
    
    private var statisticService: StatisticServiceProtocol!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        statisticService = StatisticService()
       
        questionFactory = QuestionFactory(delegate: self, moviesloader: MoviesLoader())
        
        showLoadingIndicator()
        
        questionFactory?.loadData()
                
        imageView.layer.masksToBounds = true
        imageView.layer.cornerRadius = 20
    }
    
    @IBAction private func yesButtonClicked(_ sender: UIButton) {
            guard let currentQuestion = currentQuestion else { return }
            
            showAnswerResult(isCorrect: currentQuestion.correctAnswer)
        }
        
    @IBAction private func noButtonClicked(_ sender: UIButton) {
        guard let currentQuestion = currentQuestion else { return }
        
        showAnswerResult(isCorrect: !currentQuestion.correctAnswer)
    }
    
    func didLoadDataFromServer() {
        
        activityIndicator.isHidden = true
        questionFactory?.requestNextQuestion()
        
    }
    
    func didFailToLoadData(with error: any Error) {
        showNetworkError(message: error.localizedDescription)
    }
    
    func didReceiveNextQuestion(question: QuizQuestion?) {
        
        guard let question = question else { return }
        
        currentQuestion = question
        let viewModel = convert(model: question)
        
        
        DispatchQueue.main.async {
            [weak self] in self?.show(quiz: viewModel) }
    }
    
    private func convert(model: QuizQuestion) -> QuizStepViewModel {
//        let questionStep = QuizStepViewModel(image: UIImage(named: model.image) ?? UIImage(), question: model.text, questionNumber: "\(currentQuestionIndex + 1)/\(questionsAmount)")
//        return questionStep
        return QuizStepViewModel(
            image: UIImage(data: model.image) ?? UIImage(),
            question: model.text,
            questionNumber: "\(currentQuestionIndex + 1) / \(questionsAmount)")
    }
    
    private func show (quiz step:QuizStepViewModel) {
        imageView.image = step.image
        textLabel.text = step.question
        counterLabel.text = step.questionNumber
        
        imageView.layer.borderWidth = 0
        
        yesButton.isEnabled = true
        noButton.isEnabled = true
    }
    
    private func show(quiz result: QuizResultViewModel) {
        
        let model = AlertModel(title: result.title, message: """
Ваш результат: \(result.text)
Количество сыгранных квизов: \(statisticService.gamesCount)
Рекорд: \(statisticService.bestGame.correct)/10 (\(statisticService.bestGame.date.dateTimeString))
Средняя точность: \(String(format: "%.2f", statisticService.totalAccuracy))%
""",
                               buttonText: result.buttonText) { [weak self] in guard let self = self else { return }
            self.correctAnswers = 0
            self.currentQuestionIndex = 0
            self.questionFactory?.requestNextQuestion()
            
        }
        AlertPresenter.show(model: model, vc: self)
    }
    
    private func showNextQuestionOrResults () {
        if currentQuestionIndex == questionsAmount - 1 {
            
            statisticService.store(correct: correctAnswers, total: questionsAmount)
            
            let text = "\(correctAnswers)/10"
            let viewModel = QuizResultViewModel(title: "Этот раунд окончен!", text: text, buttonText: "Сыграть еще раз")
            show(quiz: viewModel)
            
        } else {
            currentQuestionIndex += 1
            
            questionFactory?.requestNextQuestion()
        }
        
    }
    
    
    private func showAnswerResult(isCorrect:Bool) {
        
        noButton.isEnabled = false
        yesButton.isEnabled = false
        
        if isCorrect {
            correctAnswers += 1
        }
        
        imageView.layer.borderWidth = 8
        imageView.layer.borderColor = isCorrect ? UIColor.ypGreen.cgColor : UIColor.ypRed.cgColor
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self else { return }
            self.showNextQuestionOrResults()
            
        }
    }
    
    private func showLoadingIndicator() {
        activityIndicator.isHidden = false
        activityIndicator.startAnimating()
    }
    
    private func hideLoadingIndicator() {
        activityIndicator.stopAnimating()
        activityIndicator.isHidden = true
    }
    
    private func showNetworkError(message: String) {
        hideLoadingIndicator()
        
        let model = AlertModel(title: "Ошибка", message: message, buttonText: "Попробовать ещё раз") { [weak self] in guard let self = self else { return }
            self.currentQuestionIndex = 0
            self.correctAnswers = 0
//            self.questionFactory?.requestNextQuestion()
            self.showLoadingIndicator()
            self.questionFactory?.loadData()
        }
        
        AlertPresenter.show(model: model, vc: self)
    }
}

