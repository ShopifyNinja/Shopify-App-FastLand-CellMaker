# frozen_string_literal: true

class SyncLog < ApplicationRecord
  enum status: { in_progress: 0, success: 1, failed: -1 }

  default_scope { order(start_at: :desc) }
end
