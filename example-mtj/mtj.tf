data "databricks_current_user" "me" {}
data "databricks_spark_version" "latest" {}
data "databricks_spark_version" "latest_lts" {
  long_term_support = true
}
data "databricks_node_type" "smallest" {    
  local_disk = true
}


resource "databricks_notebook" "nb_1" {
  source = "/Users/uday.satapathy/Documents/src/GitHub/test-repo/nb-1.py"
  path   = "${data.databricks_current_user.me.home}/Terraform/notebooks/nb-1"
}

resource "databricks_notebook" "nb_2" {
  source = "/Users/uday.satapathy/Documents/src/GitHub/test-repo/nb-2.py"
  path   = "${data.databricks_current_user.me.home}/Terraform/notebooks/nb-2"
}

resource "databricks_notebook" "nb_3" {
  source = "/Users/uday.satapathy/Documents/src/GitHub/test-repo/nb-3.py"
  path   = "${data.databricks_current_user.me.home}/Terraform/notebooks/nb-3"
}

resource "databricks_cluster" "shared_01" {
  cluster_name            = "uday terraform mtj"
  spark_version           = data.databricks_spark_version.latest_lts.id
  node_type_id            = data.databricks_node_type.smallest.id
  autotermination_minutes = 20
  autoscale {
    min_workers = 1
    max_workers = 2
  }
}

resource "databricks_job" "this" {
  name = "Job with multiple tasks"

  job_cluster {
    job_cluster_key = "j"
    new_cluster {
      num_workers   = 2
      spark_version = data.databricks_spark_version.latest.id
      node_type_id  = data.databricks_node_type.smallest.id
    }
  }

  task {
    task_key = "a"

    new_cluster {
      num_workers   = 1
      spark_version = data.databricks_spark_version.latest.id
      node_type_id  = data.databricks_node_type.smallest.id
    }

    notebook_task {
      notebook_path = "${databricks_notebook.nb_1.path}"
    }
  }

  task {
    task_key = "b"
    //this task will only run after task a
    depends_on {
      task_key = "a"
    }

    notebook_task {
      notebook_path = "${databricks_notebook.nb_2.path}"
    }

    existing_cluster_id = "${databricks_cluster.shared_01.id}"

  }

  task {
    task_key = "c"

    job_cluster_key = "j"

    notebook_task {
      notebook_path = "${databricks_notebook.nb_3.path}"
    }
  }
  
  task {
    task_key = "d"
    depends_on {
        task_key = "c"
    }
    depends_on {
        task_key = "a"
    }
    existing_cluster_id = "${databricks_cluster.shared_01.id}"

    notebook_task {
      notebook_path = "${databricks_notebook.nb_1.path}"
    }

  }
}