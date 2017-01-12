<?php

$dispatcher = new OC_Central();
$dispatcher->redirect();

class OC_Central {
	private $authUser;
	private $origPath;
	private $domain;

	function __construct() {
		$this->authUser = $_SERVER['PHP_AUTH_USER'];
		$this->domain = $_SERVER['SERVER_NAME'];
		$this->origPath = $_SERVER['ORIG_PATH_INFO'];
	}

	public function redirect() {
		$this->checkRequest();

		$url = "https://";

		$subdomain = $this->mapSubdomain();
		if ($subdomain) {
			header("Set-Cookie: shard=$subdomain");
			#$url .= $subdomain . '.';

			$url .= $this->parseDomain();
			$url .= $this->parseOcPath();

			header('Location: ' . $url, true, 302);
		}
		#echo "authUser: $this->$authUser | $subdomain";
		exit;
	}

	private function checkRequest() {
		if (!isset($this->authUser)) {
			$this->errorUnauthorized('Error: Please provide a valid username');
			exit;
		}
	}

	private function mapSubdomain() {
		if (preg_match('/^(a[0-9]{2}).*$/', $this->authUser, $matches)) {
			return $matches[1];
		} elseif ($this->parseEmailDomain() == "switch.ch") {
			return "a01";
		} elseif ($this->parseEmailDomain() == "unil.ch") {
			return "a02";
		} elseif ($this->parseEmailDomain() == "epfl.ch") {
			return "a03";
		} elseif ($this->parseEmailDomain() == "unige.ch") {
			return "a04";
		} else {
			return "a05";
		}
	}
	private function parseEmailDomain() {
		$mail = explode("@", $this->authUser);
		return $mail[1];
	}

	private function parseDomain() {
		return $this->domain;
	}

	private function parseOcPath() {
		return $this->origPath;
	}

	private function errorUnauthorized($message) {
		header('WWW-Authenticate: Basic realm="My Realm"');
		header('HTTP/1.0 401 Unauthorized');
		echo $message;
	}
}