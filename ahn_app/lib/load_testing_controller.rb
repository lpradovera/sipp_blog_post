# encoding: utf-8

class LoadTestingController < Adhearsion::CallController
  def run
    answer
    result = ask "hello-world", limit: 1
    logger.info "RESULT WAS #{result}"
    sleep 1
    hangup
  end
end
