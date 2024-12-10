/*
  공통 사항
*/

variable "name" {
  description = "ALB 구성 요소들의 이름과 tag을 선언하는데 사용될 이름."
  type        = string

  validation {
    condition     = length(var.name) <= 32
    error_message = "이름은 32자를 넘을 수 없습니다."
  }
}

/*
  네트워크 및 보안 그룹
*/

variable "vpc_id" {
  description = "ALB의 보안 그룹을 생성 할 vpc의 id"
  type        = string
}

variable "subnet_ids" {
  description = "ALB가 관리하는 subnet id 목록. 필수적으로 2개 이상의 AZ를 포함"
  type        = set(string)

  validation {
    condition     = length(var.subnet_ids) >= 2
    error_message = "ALB는 최소한 2개 이상의 AZ를 포함하는 subnet을 가져야합니다."
  }
}

variable "enable_deletion_protection" {
  description = "ALB 삭제를 불가능하게 만들어 안전하게 관리할지 여부. true로 설정된 경우 false로 변경 후에 삭제 가능"
  type        = bool
  default     = false
}

variable "idle_timeout" {
  description = "ALB에서 연결이 일정 시간동안 idle할 경우 자동으로 종료. health check 시간보다 짧을 경우 idle 상태로 판단하여 health check가 실패할 수 있습니다."
  type        = number
  default     = 60
}

variable "certificate_arn" {
  description = "ALB에서 https를 인증 받을 때 사용할 인증서의 arn"
  type        = string
}

/*
  ALB 작동 방식
*/

variable "default_target_groups" {
  description = "default target group 리스트. key 값은 32자 이하, 영어와 hyphen만 가능"

  type = map(
    object({
      health_check_path = optional(string)
      port              = number
    })
  )

  validation {
    condition     = length(var.default_target_groups) >= 1 && length(var.default_target_groups) <= 5
    error_message = "alb의 default target group은 1개 이상 5개 이하만 가능합니다."
  }
}

variable "default_targets" {
  description = "default target group 별 target. key값을 통해 target id 지정"

  type = map(
    object({
      target_group_key = string
      port             = number
    })
  )
}

variable "https_listener_rules" {
  description = "https 리스너에 추가로 연결 할 리스너 설정. priority는 1부터 50,000 사이의 값이며 중복이 있으면 안된다. key 값은 32자 이하, 영어와 hyphen만 가능"
  type = map(object({
    path              = list(string)
    host              = list(string)
    priority          = number
    health_check_path = optional(string)
    port              = number
  }))
  default = {}
}

variable "target_groups" {
  description = "listener의 key값을 통해 target group 리스트. key 값은 32자 이하, 영어와 hyphen만 가능"

  type = map(
    object({
      health_check_path = optional(string)
      port              = number
    })
  )
  default = {}

  validation {
    condition     = length(var.target_groups) <= 5
    error_message = "alb의 target group은 1개 이상 5개 이하만 가능합니다."
  }
}

variable "targets" {
  description = "target group의 key값을 통해 target id 지정"

  type = map(
    object({
      target_group_key = string
      port             = number
    })
  )
  default = {}

}
