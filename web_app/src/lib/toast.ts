import { showToast } from '../components/ui/Toast';

export type ToastType = 'success' | 'error' | 'warning' | 'info';

export const ToastUtils = {
  showSuccess(message: string) {
    showToast('success', message);
  },
  showError(message: string) {
    showToast('error', message);
  },
  showWarning(message: string) {
    showToast('warning', message);
  },
  showInfo(message: string) {
    showToast('info', message);
  },
  showNetworkError() {
    showToast('error', 'تحقق من اتصال الإنترنت');
  },
};
