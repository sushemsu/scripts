#!/usr/bin/env bash
# quick script for updating a db
set +x

# default arg opts
builtin declare -A argopts;
builtin declare -x argopts[t:]="[-t table]";
builtin declare -x argopts[d:]="[-d database]";
builtin declare -x argopts[r:]="[-r ref]";
builtin declare -x argopts[a]="add ${argopts[d:]} ${argopts[t:]}";
builtin declare -x argopts[l]="list ${argopts[r:]}}";
builtin declare -x argopts[u]="update";
builtin declare -x argopts[h]="help";

# default vars
builtin declare -x flags="$( tr ' ' '\n' <<< ${!argopts[@]} | sort --key=1.2 -r | tr -d '\n')";
builtin declare -x PW=${PW:?please set PW env var for auth to db};
builtin declare -x today=$(date +"%Y-%m-%d");
builtin declare -x database="${database:-workout}";
builtin declare -x action="${action:-list}";
builtin declare -x table="${table:-log}";
builtin declare -x ref="";

# data struct
builtin declare -A sqldata;
builtin declare -a log_keys="(\"date\" \"type\" \"reps\" \"distance\" \"laps\" \"completed\" \"target\" \"time\" \"injury\" \"missed\" \"day_weight\" \"before_weight\" \"after_weight\" \"eod_weight\")";
builtin declare -a weights_keys="(\"date\" \"init\" \"before_workout\" \"after_workout\" \"eod\" \"workout_day\")";

function populate_data() {
	case ${table} in
		weights)
			declare -a keys=$(declare -p weights_keys |grep -o "(.*)");
		;;
		log)
			declare -a keys=$(declare -p log_keys |grep -o "(.*)");
		;;
	esac

	for item in ${keys[*]}; do
		read -p "${item}: " sqldata[${item}];
	done

	[[ "${sqldata[date]}" == "today" ]] && sqldata[date]=${today}

	for item in ${!sqldata[@]}; do
		if [[ ! -z  "${sqldata[${item}]}" ]]; then
			builtin export front+="${item},";
			builtin export rear+="\"${sqldata[${item}]}\",";
		fi
	done
}


function add() {
	populate_data
	builtin export sql="insert into ${table} (${front%%,}) values (${rear%%,})";
	mysql -p"${PW}" -e "${sql};" ${database};
	mysql -p"${PW}" -e "select * from ${table} where date = \"${sqldata[date]}\"" ${database};
}

function list() {
	if [[ "${ref}" == "today" ]]; then
		mysql -p"${PW}" -e "select * from ${table} where date = \"${today}\"\G" ${database};
	elif [[ ! -z "${ref}" ]]; then
		mysql -p"${PW}" -e "select * from ${table} where ${ref%%=*} = \"${ref##*=}\"\G" ${database};
	else
		mysql -p"${PW}" -e "select * from ${table}\G" ${database};
	fi
}

while builtin getopts "d:r:t:ulha" options; do
	case ${options} in
		a)
			builtin export action="add";
		;;
		l)
			builtin export action="list";
		;;
		d)
			builtin export database="${OPTARG}";
		;;
		t)
			builtin export table="${OPTARG}";
		;;
		u)
			builtin export action="update";
		;;
		r)
			builtin export ref="${OPTARG}";
		;;
		h)
			set --
			builtin export action="";
			builtin echo "${0}"
			for key in ${!argopts[@]}; do
				builtin echo -e "\t-${key%%:} -- ${argopts[${key}]}";
			done
		;;
	esac
done

${action}
