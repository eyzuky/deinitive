(function () {
  const STORAGE_KEY = 'memwatch-learn:progress';

  function getProgress() {
    try {
      return JSON.parse(localStorage.getItem(STORAGE_KEY) || '{}');
    } catch (_) {
      return {};
    }
  }

  function setProgress(lessonId, score) {
    const all = getProgress();
    all[lessonId] = score;
    localStorage.setItem(STORAGE_KEY, JSON.stringify(all));
  }

  // Clickable inline callouts: <span class="callout" data-target="id">term</span>
  // followed by <div class="callout-body" id="id">explanation</div>
  function initCallouts() {
    document.querySelectorAll('.callout').forEach((el) => {
      el.setAttribute('role', 'button');
      el.setAttribute('tabindex', '0');
      const open = () => {
        const id = el.getAttribute('data-target');
        const body = document.getElementById(id);
        if (body) body.classList.toggle('open');
      };
      el.addEventListener('click', open);
      el.addEventListener('keydown', (e) => {
        if (e.key === 'Enter' || e.key === ' ') {
          e.preventDefault();
          open();
        }
      });
    });
  }

  // Stepper: a container with multiple .step children. Buttons advance/rewind.
  function initSteppers() {
    document.querySelectorAll('.stepper').forEach((stepper) => {
      const steps = Array.from(stepper.querySelectorAll('.step'));
      const captionEl = stepper.querySelector('.diagram-step');
      const prevBtn = stepper.querySelector('.step-prev');
      const nextBtn = stepper.querySelector('.step-next');
      const counterEl = stepper.querySelector('.step-counter');
      let i = 0;

      function render() {
        steps.forEach((s, idx) => {
          s.style.display = idx === i ? '' : 'none';
        });
        if (captionEl) captionEl.textContent = steps[i].getAttribute('data-caption') || '';
        if (counterEl) counterEl.textContent = (i + 1) + ' / ' + steps.length;
        if (prevBtn) prevBtn.disabled = i === 0;
        if (nextBtn) nextBtn.disabled = i === steps.length - 1;
      }

      if (prevBtn) prevBtn.addEventListener('click', () => { if (i > 0) { i--; render(); } });
      if (nextBtn) nextBtn.addEventListener('click', () => { if (i < steps.length - 1) { i++; render(); } });
      render();
    });
  }

  // Quiz: <form class="quiz" data-lesson="id"> with <fieldset class="quiz-q" data-correct="b">
  // each containing <label><input type="radio" name="qN" value="a">...</label>
  function initQuiz() {
    document.querySelectorAll('.quiz').forEach((quiz) => {
      const lessonId = quiz.getAttribute('data-lesson');
      const gradeBtn = quiz.querySelector('.grade-btn');
      const summaryEl = quiz.querySelector('.quiz-summary');
      const questions = Array.from(quiz.querySelectorAll('.quiz-q'));

      if (!gradeBtn) return;

      gradeBtn.addEventListener('click', (e) => {
        e.preventDefault();
        let correct = 0;
        questions.forEach((q) => {
          const correctAnswer = q.getAttribute('data-correct');
          const labels = Array.from(q.querySelectorAll('label'));
          const selected = q.querySelector('input[type=radio]:checked');
          q.classList.add('graded');
          labels.forEach((l) => {
            const inp = l.querySelector('input');
            if (inp.value === correctAnswer) l.classList.add('correct');
            if (selected && inp === selected && inp.value !== correctAnswer) l.classList.add('wrong');
          });
          if (selected && selected.value === correctAnswer) correct++;
        });
        const total = questions.length;
        if (summaryEl) {
          summaryEl.textContent = correct + ' / ' + total + ' correct';
        }
        quiz.classList.add('graded');
        if (lessonId) setProgress(lessonId, { correct, total, when: Date.now() });
        renderProgressDots();
      });
    });
  }

  // Progress dots on index page. Looks for <li data-lesson="id">.
  function renderProgressDots() {
    const progress = getProgress();
    document.querySelectorAll('[data-lesson]').forEach((el) => {
      const id = el.getAttribute('data-lesson');
      const dot = el.querySelector('.dot');
      if (!dot) return;
      const score = progress[id];
      if (score && score.correct === score.total) {
        dot.textContent = '●';
        dot.classList.add('complete');
        dot.title = 'completed (' + score.correct + '/' + score.total + ')';
      } else if (score) {
        dot.textContent = '◐';
        dot.classList.remove('complete');
        dot.title = 'attempted (' + score.correct + '/' + score.total + ')';
      } else {
        dot.textContent = '○';
        dot.classList.remove('complete');
        dot.title = 'not started';
      }
    });

    const summary = document.getElementById('overall-progress');
    if (summary) {
      const ids = Array.from(document.querySelectorAll('[data-lesson]')).map((el) => el.getAttribute('data-lesson'));
      const done = ids.filter((id) => progress[id] && progress[id].correct === progress[id].total).length;
      summary.textContent = done + ' / ' + ids.length + ' lessons complete';
    }
  }

  // Reset button on index
  function initReset() {
    const btn = document.getElementById('reset-progress');
    if (!btn) return;
    btn.addEventListener('click', () => {
      if (confirm('Clear progress for all lessons?')) {
        localStorage.removeItem(STORAGE_KEY);
        renderProgressDots();
      }
    });
  }

  document.addEventListener('DOMContentLoaded', () => {
    initCallouts();
    initSteppers();
    initQuiz();
    renderProgressDots();
    initReset();
  });
})();
